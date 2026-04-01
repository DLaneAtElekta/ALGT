defmodule ClarionSim.Eval do
  @moduledoc """
  Expression evaluation for the Clarion simulator.

  Replaces simulator_eval.pl — handles literals, variables, binary operators,
  logical operations, array access, and control references.
  """

  alias ClarionSim.State

  @doc "Evaluate an expression in the given state, returning {value, state}."
  def eval_expr(expr, %State{} = state) do
    case expr do
      {:string, s} ->
        {s, state}

      {:number, n} ->
        {n, state}

      {:neg, n} ->
        {-n, state}

      true ->
        {1, state}

      false ->
        {0, state}

      {:var, name} ->
        if clarion_constant?(name) do
          {name, state}
        else
          case State.get_var(state, name) do
            {:ok, val} -> {val, state}
            :error -> raise "Undefined variable '#{name}'"
          end
        end

      {:binop, op, left, right} ->
        {l_val, state} = eval_expr(left, state)
        {r_val, state} = eval_expr(right, state)
        {eval_binop(op, l_val, r_val), state}

      {:not, inner} ->
        {val, state} = eval_expr(inner, state)
        {if(truthy?(val), do: 0, else: 1), state}

      {:control_ref, name} ->
        case State.get_var(state, {:equate, name}) do
          {:ok, val} -> {val, state}
          :error -> {0, state}
        end

      {:array_access, array_name, index_expr} ->
        {index, state} = eval_expr(index_expr, state)

        case State.get_var(state, array_name) do
          {:ok, {:array, elements}} ->
            idx = index - 1
            {Enum.at(elements, idx, 0), state}

          _ ->
            {0, state}
        end

      {:picture, pic} ->
        {{:picture, pic}, state}

      # Function calls — delegated to simulator
      {:call, name, args} ->
        ClarionSim.Simulator.exec_call(name, args, state)

      # Method calls
      {:method_call, obj, method, args} ->
        ClarionSim.Simulator.exec_method_call(obj, method, args, state)

      # SELF property access
      {:self_access, prop_name} ->
        case state.self do
          %{var_name: var_name} ->
            {:ok, {:instance, _, props}} = State.get_var(state, var_name)

            case List.keyfind(props, prop_name, 0) do
              {_, val} -> {val, state}
              nil -> {0, state}
            end

          _ ->
            {0, state}
        end

      # Member access (ObjName.PropName)
      {:member_access, obj_name, prop_name} ->
        case State.get_var(state, obj_name) do
          {:ok, {:instance, _, props}} ->
            case List.keyfind(props, prop_name, 0) do
              {_, val} -> {val, state}
              nil -> {0, state}
            end

          {:ok, {:group_val, _, fields, values}} ->
            case field_index(fields, prop_name) do
              {:ok, idx} -> {Enum.at(values, idx), state}
              :error -> {0, state}
            end

          _ ->
            {0, state}
        end

      other ->
        raise "Unknown expression: #{inspect(other)}"
    end
  end

  @doc "Evaluate a binary operator."
  def eval_binop(op, l, r) do
    case op do
      :+ ->
        if is_number(l) and is_number(r) do
          l + r
        else
          to_string_val(l) <> to_string_val(r)
        end

      :- ->
        l - r

      :* ->
        l * r

      :/ ->
        if r != 0 do
          if is_integer(l) and is_integer(r), do: div(l, r), else: l / r
        else
          0
        end

      :% ->
        if r != 0, do: rem(l, r), else: 0

      :& ->
        to_string_val(l) <> to_string_val(r)

      := ->
        if l == r, do: 1, else: 0

      :<> ->
        if l != r, do: 1, else: 0

      :< ->
        if l < r, do: 1, else: 0

      :> ->
        if l > r, do: 1, else: 0

      :<= ->
        if l <= r, do: 1, else: 0

      :>= ->
        if l >= r, do: 1, else: 0

      op when op in [:AND, :and] ->
        if truthy?(l) and truthy?(r), do: 1, else: 0

      op when op in [:OR, :or] ->
        if truthy?(l) or truthy?(r), do: 1, else: 0
    end
  end

  @doc "Check if a value is truthy (non-zero number, non-empty string)."
  def truthy?(val) do
    case val do
      0 -> false
      0.0 -> false
      "" -> false
      nil -> false
      false -> false
      _ when is_number(val) -> true
      _ when is_binary(val) -> val != ""
      _ when is_atom(val) -> val != :"" and val != nil and val != false
      _ -> true
    end
  end

  @doc "Convert a value to string."
  def to_string_val(val) do
    case val do
      s when is_binary(s) -> s
      a when is_atom(a) -> Atom.to_string(a)
      n when is_integer(n) -> Integer.to_string(n)
      n when is_float(n) -> Float.to_string(n)
      _ -> inspect(val)
    end
  end

  @doc "Check if a name is a Clarion system constant (EVENT:, BUTTON:, etc.)."
  def clarion_constant?(name) when is_atom(name) do
    str = Atom.to_string(name)

    String.starts_with?(str, "EVENT:") or
      String.starts_with?(str, "BUTTON:") or
      String.starts_with?(str, "ICON:") or
      String.starts_with?(str, "PROP:")
  end

  def clarion_constant?(_), do: false

  defp field_index(fields, name) do
    case Enum.find_index(fields, fn {:field, n, _, _} -> n == name end) do
      nil -> :error
      idx -> {:ok, idx}
    end
  end
end
