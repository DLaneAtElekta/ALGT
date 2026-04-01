defmodule ClarionSim.ASTBridge do
  @moduledoc """
  Translates the simple parser AST (from Erlog DCG parser) into the
  modular AST format expected by the Elixir simulator.

  Replaces ast_bridge.pl — pure Elixir pattern matching.

  Simple AST (parser output):
    {:program, files, groups, globals, map_entries, procedures}

  Modular AST (simulator input):
    {:program, {:map, map_decls}, global_decls, {:code, main_body}, procedures}
  """

  # Public test helpers
  def bridge_expr_public(expr), do: bridge_expr(expr)
  def bridge_type_public(type), do: bridge_type(type)

  @doc "Bridge a simple AST to the modular format."
  def bridge({:program, files, groups, globals, map_entries, procedures}) do
    map_decls = bridge_map_entries(map_entries)
    file_decls = Enum.map(files, &bridge_file/1)
    group_decls = Enum.map(groups, &bridge_group/1)
    global_decls = Enum.map(globals, &bridge_global/1)
    bridged_procs = Enum.map(procedures, &bridge_procedure/1)

    # Extract _main procedure if present (PROGRAM form)
    {main_body, other_procs} = extract_main(bridged_procs)

    all_globals = file_decls ++ group_decls ++ global_decls

    {:program, {:map, map_decls}, all_globals, {:code, main_body}, other_procs}
  end

  # ── MAP Entries ──

  defp bridge_map_entries(entries) do
    Enum.flat_map(entries, fn
      {:module_entry, mod_name, sub_entries} ->
        Enum.map(sub_entries, fn entry ->
          bridged = bridge_map_entry(entry)
          %{bridged | type: :external, module: mod_name}
        end)

      entry ->
        [bridge_map_entry(entry)]
    end)
  end

  defp bridge_map_entry({:map_entry, name, params, ret_type, attrs}) do
    bridged_params = Enum.map(params, &bridge_param/1)
    bridged_ret = bridge_type(ret_type)

    bridged_attrs =
      Enum.map(attrs, fn
        {:name, n} -> {:name, n}
        :export -> :export
        :c_conv -> :c_conv
        other -> other
      end)

    %{
      type: :local,
      name: name,
      params: bridged_params,
      return_type: bridged_ret,
      attrs: bridged_attrs,
      module: nil
    }
  end

  # ── File Declarations ──

  defp bridge_file({:file, name, prefix, attrs, contents}) do
    bridged_contents = Enum.map(contents, &bridge_file_content/1)
    bridged_attrs = if prefix && prefix != :none, do: [pre: prefix], else: []
    bridged_attrs = bridged_attrs ++ Enum.flat_map(attrs, fn a -> [a] end)
    {:file, name, bridged_attrs, bridged_contents}
  end

  defp bridge_file_content({:key, name, fields, attrs}) do
    {:key, name, fields, attrs}
  end

  defp bridge_file_content({:record, fields}) do
    {:record, Enum.map(fields, &bridge_field/1)}
  end

  defp bridge_file_content(other), do: other

  # ── Group Declarations ──

  defp bridge_group({:group, name, prefix, fields}) do
    bridged_fields = Enum.map(fields, &bridge_field/1)
    prefix = if prefix == :none, do: nil, else: prefix
    {:group, name, prefix, bridged_fields}
  end

  # ── Global Variables ──

  defp bridge_global({:global, name, type, init}) do
    bridged_type = bridge_type(type)

    case init do
      :none -> {:var, name, bridged_type, :none}
      value -> {:var, name, bridged_type, {:init, bridge_expr(value)}}
    end
  end

  defp bridge_global({:equate, name, value}) do
    {:var, name, :LONG, {:init, bridge_expr(value)}}
  end

  defp bridge_global(other), do: other

  # ── Procedures ──

  defp bridge_procedure({:procedure, name, params, ret_type, locals, body}) do
    bridged_params = Enum.map(params, &bridge_param/1)
    bridged_locals = Enum.map(locals, &bridge_local/1)
    bridged_body = Enum.map(body, &bridge_stmt/1)
    bridged_ret = bridge_type(ret_type)

    {:procedure, name, bridged_params, bridged_ret, bridged_locals, bridged_body}
  end

  # ── Parameters ──

  defp bridge_param({:param, name, {:ref, type}}) do
    {bridge_type(type), name}
  end

  defp bridge_param({:param, name, type}) do
    {bridge_type(type), name}
  end

  # ── Local Variables ──

  defp bridge_local({:local, name, type, init}) do
    bridged_type = bridge_type(type)

    case init do
      :none -> {:local_var, name, bridged_type, :none}
      value -> {:local_var, name, bridged_type, {:init, bridge_expr(value)}}
    end
  end

  defp bridge_local(other), do: other

  # ── Fields ──

  defp bridge_field({:field, name, type, size}) do
    {:field, name, bridge_type(type), size}
  end

  # ── Type Bridging ──

  defp bridge_type(:long), do: :LONG
  defp bridge_type(:short), do: :SHORT
  defp bridge_type(:byte), do: :BYTE
  defp bridge_type(:real), do: :REAL
  defp bridge_type(:sreal), do: :SREAL
  defp bridge_type(:date), do: :DATE
  defp bridge_type(:time), do: :TIME
  defp bridge_type(:decimal), do: :DECIMAL
  defp bridge_type(:pdecimal), do: :PDECIMAL
  defp bridge_type(:string), do: :STRING
  defp bridge_type({:cstring, _}), do: :CSTRING
  defp bridge_type(:cstring), do: :CSTRING
  defp bridge_type(:pstring), do: :PSTRING
  defp bridge_type(:void), do: :void
  defp bridge_type({:ref, t}), do: bridge_type(t)
  defp bridge_type(t) when is_atom(t), do: t

  # ── Statement Bridging ──

  defp bridge_stmt(stmt) do
    case stmt do
      {:assign, name, expr} ->
        {:assign, name, bridge_expr(expr)}

      {:assign_add, name, expr} ->
        {:assign_add, name, bridge_expr(expr)}

      {:call, name, args} ->
        {:call, name, Enum.map(args, &bridge_expr/1)}

      {:return, expr} ->
        {:return, bridge_expr(expr)}

      :return ->
        :return

      {:if, cond_expr, then_stmts, else_stmts} ->
        {:if, bridge_expr(cond_expr),
         Enum.map(then_stmts, &bridge_stmt/1),
         [],
         Enum.map(else_stmts, &bridge_stmt/1)}

      {:loop, body} ->
        {:loop, Enum.map(body, &bridge_stmt/1)}

      {:loop_for, var, start_expr, end_expr, body} ->
        {:loop_to, var,
         bridge_expr(start_expr),
         bridge_expr(end_expr),
         Enum.map(body, &bridge_stmt/1)}

      {:loop_while, cond_expr, body} ->
        {:loop_while, bridge_expr(cond_expr),
         Enum.map(body, &bridge_stmt/1)}

      {:loop_until, cond_expr, body} ->
        {:loop_until, bridge_expr(cond_expr),
         Enum.map(body, &bridge_stmt/1)}

      :break -> :break
      :cycle -> :cycle
      :exit -> :exit
      :display -> :display

      {:case, expr, cases, else_stmts} ->
        {:case, bridge_expr(expr),
         Enum.map(cases, &bridge_case/1),
         Enum.map(else_stmts, &bridge_stmt/1)}

      {:accept, body} ->
        {:accept, Enum.map(body, &bridge_stmt/1)}

      {:do, name} ->
        {:do, name}

      other ->
        other
    end
  end

  # ── Case Branch Bridging ──

  defp bridge_case({:of, {:range, start_expr, end_expr}, body}) do
    {:case_of,
     {:range, bridge_expr(start_expr), bridge_expr(end_expr)},
     Enum.map(body, &bridge_stmt/1)}
  end

  defp bridge_case({:of, {:single, val}, body}) do
    {:case_of, bridge_expr(val), Enum.map(body, &bridge_stmt/1)}
  end

  defp bridge_case({:of, val, body}) do
    {:case_of, bridge_expr(val), Enum.map(body, &bridge_stmt/1)}
  end

  # ── Expression Bridging ──

  defp bridge_expr(expr) do
    case expr do
      {:lit, n} when is_integer(n) -> {:number, n}
      {:lit, n} when is_float(n) -> {:number, n}
      {:lit, s} when is_atom(s) -> {:string, Atom.to_string(s)}
      {:lit, s} when is_binary(s) -> {:string, s}

      {:var, name} -> {:var, name}
      {:neg, e} -> {:neg, bridge_expr(e)}

      {:add, a, b} -> {:binop, :+, bridge_expr(a), bridge_expr(b)}
      {:sub, a, b} -> {:binop, :-, bridge_expr(a), bridge_expr(b)}
      {:mul, a, b} -> {:binop, :*, bridge_expr(a), bridge_expr(b)}
      {:div, a, b} -> {:binop, :/, bridge_expr(a), bridge_expr(b)}
      {:modulo, a, b} -> {:binop, :%, bridge_expr(a), bridge_expr(b)}
      {:concat, a, b} -> {:binop, :&, bridge_expr(a), bridge_expr(b)}

      {:eq, a, b} -> {:binop, :=, bridge_expr(a), bridge_expr(b)}
      {:neq, a, b} -> {:binop, :<>, bridge_expr(a), bridge_expr(b)}
      {:lt, a, b} -> {:binop, :<, bridge_expr(a), bridge_expr(b)}
      {:gt, a, b} -> {:binop, :>, bridge_expr(a), bridge_expr(b)}
      {:lte, a, b} -> {:binop, :<=, bridge_expr(a), bridge_expr(b)}
      {:gte, a, b} -> {:binop, :>=, bridge_expr(a), bridge_expr(b)}

      {:and, a, b} -> {:binop, :and, bridge_expr(a), bridge_expr(b)}
      {:or, a, b} -> {:binop, :or, bridge_expr(a), bridge_expr(b)}
      {:not, a} -> {:not, bridge_expr(a)}

      {:call, name, args} -> {:call, name, Enum.map(args, &bridge_expr/1)}

      {:equate, name} -> {:control_ref, name}

      {:array_ref, name, index} -> {:array_access, name, bridge_expr(index)}

      # Pass through already-bridged forms
      {:number, _} = e -> e
      {:string, _} = e -> e
      {:binop, _, _, _} = e -> e
      {:control_ref, _} = e -> e

      other -> other
    end
  end

  # ── Main Procedure Extraction ──

  defp extract_main(procedures) do
    case Enum.split_with(procedures, fn
      {:procedure, :_main, _, _, _, _} -> true
      _ -> false
    end) do
      {[{:procedure, :_main, _, _, _locals, body}], others} ->
        {body, others}

      {[], others} ->
        {[], others}
    end
  end
end
