defmodule ClarionSim.Simulator do
  @moduledoc """
  Clarion AST execution engine — replaces simulator.pl.

  Executes the modular AST produced by the AST bridge. Handles statement
  dispatch, procedure calls, control flow, and ACCEPT loop event processing.

  All functions thread an immutable State struct using the pattern:
    {result, new_state} or {value, new_state, control}
  """

  alias ClarionSim.{State, Eval, Builtins, Classes, Control}
  alias ClarionSim.Storage.FileState

  # ── Main Entry Points ──

  @doc "Execute a full program AST."
  def run_ast({:program, {:map, map_decls}, global_decls, {:code, statements}, procedures}) do
    state = State.empty()
    state = init_map_protos(map_decls, state)
    state = init_procedures(procedures, state)
    state = init_globals(global_decls, state)
    {_control, state} = exec_statements(statements, state)
    state
  end

  def run_ast({:program, _, global_decls, {:code, statements}, procedures}) do
    state = State.empty()
    state = init_procedures(procedures, state)
    state = init_globals(global_decls, state)
    {_control, state} = exec_statements(statements, state)
    state
  end

  # ── Initialization ──

  def init_map_protos(map_decls, state) do
    %{state | map_protos: map_decls}
  end

  def init_procedures(procedures, state) do
    Enum.reduce(procedures, state, fn proc, acc ->
      case proc do
        {:procedure, name, params, _ret_type, locals, body} ->
          proc_def = %{name: name, params: params, locals: locals, body: body}
          %{acc | procs: Map.put(acc.procs, name, proc_def)}

        {:routine, name, body} ->
          %{acc | procs: Map.put(acc.procs, {:routine, name}, body)}

        {:method_impl, class, method, params, locals, body} ->
          impl = %{class: class, method: method, params: params, locals: locals, body: body}
          %{acc | procs: Map.put(acc.procs, {:method, class, method}, impl)}

        _ ->
          acc
      end
    end)
  end

  def init_globals(global_decls, state) do
    Enum.reduce(global_decls, state, fn decl, acc ->
      case decl do
        {:var, name, _type, {:init, init_val}} when init_val != :none ->
          State.set_var(acc, name, init_val)

        {:var, name, type, size_spec} ->
          State.set_var(acc, name, State.default_value(type, size_spec))

        {:file, name, attrs, contents} ->
          init_file(acc, name, attrs, contents)

        {:class, name, parent, attrs, members} ->
          Classes.init_class(acc, name, parent, attrs, members)

        {:group, name, prefix, fields} ->
          init_group(acc, name, prefix, fields)

        {:group, name, fields} ->
          init_group(acc, name, nil, fields)

        {:queue, name, fields} ->
          buffer = FileState.create_default_buffer(fields)
          fs = %FileState{name: name, prefix: nil, keys: [], fields: fields, buffer: buffer, is_open: true}
          State.set_file_state(acc, name, fs)

        {:window, _name, _title, _attrs, controls} ->
          assign_equates(controls, 1, acc)

        _ ->
          acc
      end
    end)
  end

  # ── Statement Execution ──

  @doc """
  Execute a list of statements. Returns {control, state} where
  control is :normal, :break, :cycle, :return, or {:return, value}.
  """
  def exec_statements([], state), do: {:normal, state}

  def exec_statements([stmt | rest], state) do
    {control, state} = exec_statement(stmt, state)

    case control do
      :normal -> exec_statements(rest, state)
      _ -> {control, state}
    end
  end

  @doc "Execute a single statement."
  def exec_statement(stmt, state) do
    case stmt do
      {:call, name, args} ->
        {_result, state} = exec_call(name, args, state)
        {:normal, state}

      {:assign, var_name, expr} ->
        {value, state} = Eval.eval_expr(expr, state)
        {:normal, State.set_var(state, var_name, value)}

      {:method_call, obj_name, method_name, args} ->
        {_result, state, _} = exec_method_call(obj_name, method_name, args, state)
        {:normal, state}

      {:self_assign, prop_name, expr} ->
        {value, state} = Eval.eval_expr(expr, state)
        %{var_name: var_name} = state.self
        {:ok, instance} = State.get_var(state, var_name)
        new_instance = Classes.set_instance_prop(instance, prop_name, value)
        {:normal, State.set_var(state, var_name, new_instance)}

      {:member_assign, var_name, field_name, expr} ->
        {value, state} = Eval.eval_expr(expr, state)
        exec_member_assign(state, var_name, field_name, value)

      {:array_assign, array_name, index_expr, expr} ->
        {index, state} = Eval.eval_expr(index_expr, state)
        {value, state} = Eval.eval_expr(expr, state)

        case State.get_var(state, array_name) do
          {:ok, {:array, elements}} ->
            idx = index - 1
            new_elements = List.replace_at(elements, idx, value)
            {:normal, State.set_var(state, array_name, {:array, new_elements})}

          _ ->
            {:normal, State.set_var(state, array_name, value)}
        end

      {:assign_add, var_name, expr} ->
        {val, state} = Eval.eval_expr(expr, state)
        {:ok, current} = State.get_var(state, var_name)
        {:normal, State.set_var(state, var_name, current + val)}

      :return ->
        {:return, state}

      {:return, expr} ->
        {value, state} = Eval.eval_expr(expr, state)
        {{:return, value}, state}

      {:if, cond_expr, then_stmts, elsif_clauses, else_stmts} ->
        {cond_val, state} = Eval.eval_expr(cond_expr, state)

        if Eval.truthy?(cond_val) do
          exec_statements(then_stmts, state)
        else
          exec_elsifs(elsif_clauses, else_stmts, state)
        end

      {:if, cond_expr, then_stmts, else_stmts} ->
        {cond_val, state} = Eval.eval_expr(cond_expr, state)

        if Eval.truthy?(cond_val) do
          exec_statements(then_stmts, state)
        else
          exec_statements(else_stmts, state)
        end

      {:loop, body} ->
        exec_loop_infinite(body, state)

      {:loop_to, var, from_expr, to_expr, body} ->
        {from, state} = Eval.eval_expr(from_expr, state)
        {to, state} = Eval.eval_expr(to_expr, state)
        state = State.set_var(state, var, from)
        exec_loop_to(var, to, body, state)

      {:loop_while, cond_expr, body} ->
        exec_loop_while(cond_expr, body, state)

      {:loop_until, cond_expr, body} ->
        exec_loop_until(cond_expr, body, state)

      :break ->
        {:break, state}

      :cycle ->
        {:cycle, state}

      {:case, expr, cases, else_stmts} ->
        {value, state} = Eval.eval_expr(expr, state)
        exec_case(value, cases, else_stmts, state)

      {:do, routine_name} ->
        exec_routine(routine_name, state)

      :exit ->
        {:exit, state}

      {:accept, body} ->
        exec_accept_loop(body, state)

      # No-ops for non-GUI
      {:control_prop_assign, _, _, _} -> {:normal, state}
      {:select, _} -> {:normal, state}
      :beep -> {:normal, state}
      :display -> {:normal, state}

      _ ->
        {:normal, state}
    end
  end

  # ── Procedure/Function Calls ──

  @doc "Execute a procedure call. Returns {result, state}."
  def exec_call(name, args, state) do
    # Try builtins first
    case Builtins.call(name, args, state) do
      {:ok, result, new_state} ->
        {result, new_state}

      :not_builtin ->
        if State.is_external_proc?(state, name) do
          exec_external_stub(name, args, state)
        else
          case State.get_proc(state, name) do
            {:ok, proc_def} ->
              exec_user_proc(name, proc_def, args, state)

            :error ->
              raise "Undefined procedure '#{name}'"
          end
        end
    end
  end

  defp exec_user_proc(_name, proc_def, args, state) do
    {arg_vals, state} = eval_args(args, state)

    state = bind_params(proc_def.params, arg_vals, state)
    state = init_locals(proc_def.locals, state)
    outer_vars = state.vars
    {control, inner_state} = exec_statements(proc_def.body, state)

    result = case control do
      {:return, v} -> v
      _ -> :none
    end

    # Merge globals back
    merged_vars = merge_globals(outer_vars, inner_state.vars, proc_def.params, proc_def.locals)

    new_state = %{inner_state |
      vars: merged_vars,
      procs: state.procs,
      self: nil,
      ui_state: state.ui_state,
      continuation: state.continuation
    }

    {result, new_state}
  end

  defp exec_external_stub(name, args, state) do
    {arg_vals, state} = eval_args(args, state)

    # Special case: MemCopy is a no-op
    if name == :MemCopy do
      {0, state}
    else
      IO.puts("  [EXTERNAL #{name}(#{inspect(arg_vals)}) -> 0]")
      {0, state}
    end
  end

  @doc "Execute a method call on an object instance."
  def exec_method_call(obj_name, method_name, args, state) do
    {:ok, instance} = State.get_var(state, obj_name)
    {:instance, class_name, _props} = instance

    case Classes.find_method_impl(state, class_name, method_name) do
      {:ok, method_impl} ->
        {arg_vals, state} = eval_args(args, state)

        {:ok, class_def} = Classes.get_class_def(state, class_name)
        state = State.set_self(state, %{var_name: obj_name, class: method_impl.class, parent: class_def.parent})
        state = bind_params(method_impl.params, arg_vals, state)
        state = init_locals(method_impl.locals, state)

        {control, state} = exec_statements(method_impl.body, state)
        result = case control do
          {:return, v} -> v
          _ -> :none
        end

        {result, State.set_self(state, nil), :normal}

      :error ->
        raise "Method '#{class_name}.#{method_name}' not found"
    end
  end

  # ── ELSIF Handling ──

  defp exec_elsifs([], else_stmts, state) do
    exec_statements(else_stmts, state)
  end

  defp exec_elsifs([{:elsif, cond_expr, stmts} | rest], else_stmts, state) do
    {cond_val, state} = Eval.eval_expr(cond_expr, state)

    if Eval.truthy?(cond_val) do
      exec_statements(stmts, state)
    else
      exec_elsifs(rest, else_stmts, state)
    end
  end

  # ── Loop Execution ──

  defp exec_loop_infinite(body, state) do
    {control, state} = exec_statements(body, state)

    case control do
      :break -> {:normal, state}
      :return -> {:return, state}
      {:return, _} = ret -> {ret, state}
      _ -> exec_loop_infinite(body, state)
    end
  end

  defp exec_loop_to(var, to, body, state) do
    {:ok, current} = State.get_var(state, var)

    if current > to do
      {:normal, state}
    else
      {control, state} = exec_statements(body, state)

      case control do
        :break -> {:normal, state}
        :return -> {:return, state}
        {:return, _} = ret -> {ret, state}
        _ ->
          state = State.set_var(state, var, current + 1)
          exec_loop_to(var, to, body, state)
      end
    end
  end

  defp exec_loop_while(cond_expr, body, state) do
    {cond_val, state} = Eval.eval_expr(cond_expr, state)

    if Eval.truthy?(cond_val) do
      {control, state} = exec_statements(body, state)

      case control do
        :break -> {:normal, state}
        :return -> {:return, state}
        {:return, _} = ret -> {ret, state}
        _ -> exec_loop_while(cond_expr, body, state)
      end
    else
      {:normal, state}
    end
  end

  defp exec_loop_until(cond_expr, body, state) do
    {control, state} = exec_statements(body, state)

    case control do
      :break -> {:normal, state}
      :return -> {:return, state}
      {:return, _} = ret -> {ret, state}
      _ ->
        {cond_val, state} = Eval.eval_expr(cond_expr, state)

        if Eval.truthy?(cond_val) do
          {:normal, state}
        else
          exec_loop_until(cond_expr, body, state)
        end
    end
  end

  # ── CASE Execution ──

  defp exec_case(value, cases, else_stmts, state) do
    case find_matching_case(value, cases, state) do
      {:match, stmts, state} -> exec_statements(stmts, state)
      {:else, state} -> exec_statements(else_stmts, state)
    end
  end

  defp find_matching_case(_value, [], state), do: {:else, state}

  defp find_matching_case(value, [{:case_of, {:range, start_expr, end_expr}, stmts} | rest], state) do
    {start_val, state} = Eval.eval_expr(start_expr, state)
    {end_val, state} = Eval.eval_expr(end_expr, state)

    if is_number(value) and value >= start_val and value <= end_val do
      {:match, stmts, state}
    else
      find_matching_case(value, rest, state)
    end
  end

  defp find_matching_case(value, [{:case_of, case_expr, stmts} | rest], state) do
    {match_val, state} = Eval.eval_expr(case_expr, state)

    if value == match_val do
      {:match, stmts, state}
    else
      find_matching_case(value, rest, state)
    end
  end

  # ── Routine Execution ──

  defp exec_routine(name, state) do
    case Control.get_routine(state, name) do
      {:ok, body} ->
        {control, state} = exec_statements(body, state)
        control = if control == :exit, do: :normal, else: control
        {control, state}

      {:error, reason} ->
        raise "#{inspect(reason)}"
    end
  end

  # ── ACCEPT Loop ──

  defp exec_accept_loop(body, state) do
    ui = state.ui_state

    case ui.event_queue do
      [event | rest] ->
        new_ui = %{ui | event_queue: rest}
        state = State.set_ui_state(state, new_ui)

        case event do
          {:set, var_name, value} ->
            state = State.set_var(state, var_name, value)
            exec_accept_loop(body, state)

          {:choice, eq_name, index} ->
            key = :"__CHOICE__#{eq_name}"
            state = State.set_var(state, key, index)
            exec_accept_loop(body, state)

          _ when is_integer(event) ->
            state = State.set_var(state, :__ACCEPTED__, event)
            {control, state} = exec_statements(body, state)

            case control do
              :break -> {:normal, state}
              {:return, _} = ret -> {ret, state}
              _ -> exec_accept_loop(body, state)
            end

          _ ->
            exec_accept_loop(body, state)
        end

      [] ->
        {:normal, state}
    end
  end

  # ── Member Assignment ──

  defp exec_member_assign(state, var_name, field_name, value) do
    case State.get_file_state(state, var_name) do
      {:ok, fs} ->
        new_fs = FileState.set_buffer_field(fs, field_name, value)
        {:normal, State.set_file_state(state, var_name, new_fs)}

      :error ->
        case State.get_var(state, var_name) do
          {:ok, {:group_val, pfx, fields, values}} ->
            case field_index(fields, field_name) do
              {:ok, idx} ->
                new_values = List.replace_at(values, idx, value)
                {:normal, State.set_var(state, var_name, {:group_val, pfx, fields, new_values})}

              :error ->
                {:normal, state}
            end

          {:ok, {:instance, _, _} = inst} ->
            new_inst = Classes.set_instance_prop(inst, field_name, value)
            {:normal, State.set_var(state, var_name, new_inst)}

          _ ->
            {:normal, state}
        end
    end
  end

  # ── Initialization Helpers ──

  defp init_file(state, name, attrs, contents) do
    prefix = Keyword.get(attrs, :pre, nil)
    driver = Keyword.get(attrs, :driver, :memory)
    keys = extract_keys(contents)
    fields = extract_record_fields(contents)
    buffer = FileState.create_default_buffer(fields)

    fs = %FileState{
      name: name,
      prefix: prefix,
      keys: keys,
      fields: fields,
      buffer: buffer,
      is_open: false
    }

    state = State.set_file_state(state, name, fs)
    State.set_var(state, {:file_driver, name}, driver)
  end

  defp init_group(state, name, prefix, fields) do
    values = Enum.map(fields, fn {:field, _, type, size} -> State.default_value(type, size) end)
    state = State.set_var(state, name, {:group_val, prefix, fields, values})

    if prefix do
      State.set_var(state, {:group_prefix, prefix}, name)
    else
      state
    end
  end

  defp assign_equates([], _n, state), do: state

  defp assign_equates([control | rest], n, state) do
    case control_equate_name(control) do
      {:ok, eq_name} ->
        state = State.set_var(state, {:equate, eq_name}, n)
        assign_equates(rest, n + 1, state)

      :none ->
        assign_equates(rest, n, state)
    end
  end

  defp control_equate_name({:button, _, _, {:equate, name}}), do: {:ok, name}
  defp control_equate_name({:entry, _, _, {:equate, name}}), do: {:ok, name}
  defp control_equate_name({:list_ctl, _, {:equate, name}, _, _}), do: {:ok, name}
  defp control_equate_name({:string_ctl, _, _, {:equate, name}}), do: {:ok, name}
  defp control_equate_name({:prompt, _, _, {:equate, name}}), do: {:ok, name}
  defp control_equate_name(_), do: :none

  defp extract_keys(contents) do
    Enum.flat_map(contents, fn
      {:key, key_name, key_fields, _attrs} -> [{key_name, key_fields}]
      _ -> []
    end)
  end

  defp extract_record_fields(contents) do
    case Enum.find(contents, fn {:record, _} -> true; _ -> false end) do
      {:record, fields} -> fields
      nil -> []
    end
  end

  defp init_locals(locals, state) do
    Enum.reduce(locals, state, fn
      {:var, name, type, size_spec} ->
        State.set_var(state, name, State.default_value(type, size_spec))

      {:local_var, name, {:custom, class_name}, _} ->
        case Classes.create_instance(state, class_name) do
          {:ok, instance} -> State.set_var(state, name, instance)
          _ -> state
        end

      {:local_var, name, _type, {:init, init_val}} when init_val != :none ->
        State.set_var(state, name, init_val)

      {:local_var, name, type, size_spec} ->
        State.set_var(state, name, State.default_value(type, size_spec))

      {:window, _, _, _} ->
        state

      _ ->
        state
    end)
  end

  defp bind_params([], _vals, state), do: state
  defp bind_params(_params, [], state), do: state

  defp bind_params([param | params], [val | vals], state) do
    name =
      case param do
        {_, n} -> n
        {_, n, :optional, _} -> n
      end

    state = State.set_var(state, name, val)
    bind_params(params, vals, state)
  end

  defp eval_args(args, state) do
    Enum.map_reduce(args, state, fn arg, acc ->
      Eval.eval_expr(arg, acc)
    end)
  end

  defp merge_globals(outer_vars, inner_vars, params, locals) do
    param_names = MapSet.new(Enum.map(params, fn
      {_, n} -> n
      {_, n, _, _} -> n
    end))

    local_names = MapSet.new(Enum.flat_map(locals, fn
      {:local_var, n, _, _} -> [n]
      {:var, n, _, _} -> [n]
      _ -> []
    end))

    excluded = MapSet.union(param_names, local_names)

    # Start with outer vars, update with inner values for non-local vars
    Map.merge(outer_vars, Map.drop(inner_vars, MapSet.to_list(excluded)), fn _k, _outer, inner ->
      inner
    end)
  end

  defp field_index(fields, name) do
    case Enum.find_index(fields, fn {:field, n, _, _} -> n == name end) do
      nil -> :error
      idx -> {:ok, idx}
    end
  end
end
