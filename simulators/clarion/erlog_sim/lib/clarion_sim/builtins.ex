defmodule ClarionSim.Builtins do
  @moduledoc """
  Built-in Clarion functions — replaces simulator_builtins.pl.

  Implements string functions, math functions, file I/O, and
  window event functions. File I/O delegates to storage backends
  via the Storage.Dispatcher.
  """

  alias ClarionSim.{State, Eval}
  alias ClarionSim.Storage.{Dispatcher, FileState}

  @doc """
  Attempt to call a built-in function.
  Returns {:ok, result, new_state} or :not_builtin.
  """
  def call(name, args, %State{} = state) do
    case do_call(name, args, state) do
      {:ok, _, _} = result -> result
      :not_builtin -> :not_builtin
    end
  end

  # ── String Functions ──

  defp do_call(:MESSAGE, args, state) do
    {texts, state} = eval_args(args, state)

    text = List.first(texts, "")
    IO.puts("MESSAGE: #{text}")
    state = State.add_output(state, {:message, text})
    {:ok, :none, state}
  end

  defp do_call(:CLIP, [expr], state) do
    {str, state} = Eval.eval_expr(expr, state)
    {:ok, String.trim_trailing(Eval.to_string_val(str)), state}
  end

  defp do_call(:TRIM, [expr], state), do: do_call(:CLIP, [expr], state)

  defp do_call(:LEFT, [expr], state) do
    {str, state} = Eval.eval_expr(expr, state)
    {:ok, String.trim_leading(Eval.to_string_val(str)), state}
  end

  defp do_call(:RIGHT, [expr], state), do: do_call(:CLIP, [expr], state)

  defp do_call(:LEN, [expr], state) do
    {str, state} = Eval.eval_expr(expr, state)
    {:ok, String.length(Eval.to_string_val(str)), state}
  end

  defp do_call(:CHR, [expr], state) do
    {code, state} = Eval.eval_expr(expr, state)
    {:ok, <<code::utf8>>, state}
  end

  defp do_call(:VAL, [expr], state) do
    {char, state} = Eval.eval_expr(expr, state)
    s = Eval.to_string_val(char)

    code =
      case String.to_charlist(s) do
        [c | _] -> c
        [] -> 0
      end

    {:ok, code, state}
  end

  defp do_call(:UPPER, [expr], state) do
    {str, state} = Eval.eval_expr(expr, state)
    {:ok, String.upcase(Eval.to_string_val(str)), state}
  end

  defp do_call(:LOWER, [expr], state) do
    {str, state} = Eval.eval_expr(expr, state)
    {:ok, String.downcase(Eval.to_string_val(str)), state}
  end

  defp do_call(:INSTRING, args, state) do
    {vals, state} = eval_args(args, state)

    {needle, haystack, start} =
      case vals do
        [n, h] -> {n, h, 1}
        [n, h, s] -> {n, h, s}
      end

    ns = Eval.to_string_val(needle)
    hs = Eval.to_string_val(haystack)
    offset = start - 1
    sub = String.slice(hs, offset..-1//1)

    result =
      case :binary.match(sub, ns) do
        {pos, _} -> pos + start
        :nomatch -> 0
      end

    {:ok, result, state}
  end

  defp do_call(:SUB, [str_expr, pos_expr, len_expr], state) do
    {str, state} = Eval.eval_expr(str_expr, state)
    {pos, state} = Eval.eval_expr(pos_expr, state)
    {len, state} = Eval.eval_expr(len_expr, state)
    s = Eval.to_string_val(str)
    start = pos - 1
    result = if start >= 0, do: String.slice(s, start, len), else: ""
    {:ok, result || "", state}
  end

  # ── Math Functions ──

  defp do_call(:ABS, [expr], state) do
    {val, state} = Eval.eval_expr(expr, state)
    {:ok, abs(val), state}
  end

  defp do_call(:INT, [expr], state) do
    {val, state} = Eval.eval_expr(expr, state)
    {:ok, trunc(val), state}
  end

  defp do_call(:ROUND, args, state) do
    {vals, state} = eval_args(args, state)

    result =
      case vals do
        [val] -> round(val)
        [val, dec] -> Float.round(val * 1.0, dec)
      end

    {:ok, result, state}
  end

  defp do_call(:SQRT, [expr], state) do
    {val, state} = Eval.eval_expr(expr, state)

    result =
      if val >= 0 do
        f = :math.sqrt(val)
        i = trunc(f)
        if f == i * 1.0, do: i, else: f
      else
        0
      end

    {:ok, result, state}
  end

  defp do_call(:POWER, [base_expr, exp_expr], state) do
    {base, state} = Eval.eval_expr(base_expr, state)
    {exp, state} = Eval.eval_expr(exp_expr, state)
    {:ok, :math.pow(base, exp), state}
  end

  # ── Date/Time ──

  defp do_call(:TODAY, [], state), do: {:ok, 80_000, state}
  defp do_call(:CLOCK, [], state), do: {:ok, 0, state}

  # ── Size/Address ──

  defp do_call(:SIZE, [{:var, name}], state) do
    size =
      case State.get_file_state(state, name) do
        {:ok, %FileState{fields: fields}} -> length(fields) * 4
        :error ->
          case State.get_var(state, name) do
            {:ok, {:group_val, _, fields, _}} -> length(fields) * 4
            _ -> 0
          end
      end

    {:ok, size, state}
  end

  defp do_call(:ADDRESS, [{:var, name}], state) do
    codes = String.to_charlist(Atom.to_string(name))
    addr = Enum.sum(codes) * 1000 + 65536
    {:ok, addr, state}
  end

  defp do_call(:ADDRESS, [_], state), do: {:ok, 65536, state}

  defp do_call(:POINTER, [{:var, file_name}], state) do
    pos =
      case State.get_file_state(state, file_name) do
        {:ok, %FileState{position: p}} -> p + 1
        :error -> 0
      end

    {:ok, pos, state}
  end

  # ── Error Functions ──

  defp do_call(:ERRORCODE, [], state), do: {:ok, state.error_code, state}

  defp do_call(:ERROR, [], state) do
    {:ok, error_message(state.error_code), state}
  end

  # ── File I/O Functions ──

  defp do_call(:CREATE, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.create(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, state}
        end

      :error ->
        {:ok, :none, State.set_error(state, 0)}
    end
  end

  defp do_call(:OPEN, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.open(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 2)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:CLOSE, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.close(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 2)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:ADD, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.add(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 2)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:GET, [{:var, file_name}, index_expr], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        case index_expr do
          {:var, key_ref} ->
            # Key-based get
            {key_name, _field_name} = resolve_key_ref(key_ref, fs.prefix)

            case find_key_def(fs.keys, key_name) do
              {:ok, {_name, key_fields}} ->
                search_values = get_key_values(key_fields, fs)
                driver = get_file_driver(state, file_name)

                case Dispatcher.get(driver, {:key_search, key_name, key_fields, search_values}, fs) do
                  {:ok, new_fs} ->
                    state = State.set_file_state(state, file_name, new_fs)
                    {:ok, :none, State.set_error(state, 0)}

                  _ ->
                    {:ok, :none, State.set_error(state, 33)}
                end

              :error ->
                {:ok, :none, State.set_error(state, 47)}
            end

          _ ->
            # Index-based get
            {index, state} = Eval.eval_expr(index_expr, state)
            pos = index - 1

            if pos >= 0 and pos < length(fs.records) do
              new_buffer = Enum.at(fs.records, pos)

              new_fs = %{fs | buffer: new_buffer, position: pos}
              state = State.set_file_state(state, file_name, new_fs)
              {:ok, :none, State.set_error(state, 0)}
            else
              {:ok, :none, State.set_error(state, 33)}
            end
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:PUT, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.put(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 33)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:DELETE, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, %FileState{position: pos} = fs} when pos >= 0 ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.delete(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 33)}
        end

      {:ok, _} ->
        {:ok, :none, State.set_error(state, 33)}

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:SET, [{:var, ref}], state) do
    case State.get_file_state(state, ref) do
      {:ok, fs} ->
        driver = get_file_driver(state, ref)

        case Dispatcher.set(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, ref, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 2)}
        end

      :error ->
        # Try as key reference
        case State.parse_prefixed_name(ref) do
          {:prefixed, prefix, _key_name} ->
            file_state = State.find_file_by_prefix(state, prefix)

            if file_state do
              driver = get_file_driver(state, file_state.name)

              case Dispatcher.set(driver, file_state) do
                {:ok, new_fs} ->
                  state = State.set_file_state(state, file_state.name, new_fs)
                  {:ok, :none, State.set_error(state, 0)}

                _ ->
                  {:ok, :none, State.set_error(state, 2)}
              end
            else
              {:ok, :none, State.set_error(state, 2)}
            end

          :simple ->
            {:ok, :none, State.set_error(state, 2)}
        end
    end
  end

  defp do_call(:NEXT, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.next(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 33)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:PREVIOUS, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, %FileState{position: pos, records: records} = fs} ->
        prev_pos = if pos < 0, do: length(records) - 1, else: pos - 1

        if prev_pos >= 0 do
          new_buffer = Enum.at(records, prev_pos)
          new_fs = %{fs | buffer: new_buffer, position: prev_pos}
          state = State.set_file_state(state, file_name, new_fs)
          {:ok, :none, State.set_error(state, 0)}
        else
          {:ok, :none, State.set_error(state, 33)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:RECORDS, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)
        {:ok, Dispatcher.records(driver, fs), state}

      :error ->
        {:ok, 0, state}
    end
  end

  defp do_call(:CLEAR, [{:var, record_ref}], state) do
    case State.parse_prefixed_name(record_ref) do
      {:prefixed, prefix, :Record} ->
        file_state = State.find_file_by_prefix(state, prefix)

        if file_state do
          driver = get_file_driver(state, file_state.name)

          case Dispatcher.clear(driver, file_state) do
            {:ok, new_fs} ->
              {:ok, :none, State.set_file_state(state, file_state.name, new_fs)}

            _ ->
              {:ok, :none, state}
          end
        else
          {:ok, :none, state}
        end

      _ ->
        {:ok, :none, state}
    end
  end

  defp do_call(:EMPTY, [{:var, file_name}], state) do
    case State.get_file_state(state, file_name) do
      {:ok, fs} ->
        driver = get_file_driver(state, file_name)

        case Dispatcher.empty(driver, fs) do
          {:ok, new_fs} ->
            state = State.set_file_state(state, file_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}

          _ ->
            {:ok, :none, State.set_error(state, 2)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  defp do_call(:FREE, [{:var, queue_name}], state) do
    do_call(:EMPTY, [{:var, queue_name}], state)
  end

  defp do_call(:SORT, [{:var, queue_name}, sort_key], state) do
    case State.get_file_state(state, queue_name) do
      {:ok, %FileState{fields: fields, records: records} = fs} ->
        field_name =
          case sort_key do
            {:var, qual_name} ->
              case State.parse_prefixed_name(qual_name) do
                {:prefixed, _, name} -> name
                :simple -> qual_name
              end

            name ->
              name
          end

        case Enum.find_index(fields, fn {:field, n, _, _} -> n == field_name end) do
          nil ->
            {:ok, :none, State.set_error(state, 0)}

          idx ->
            sorted = Enum.sort_by(records, &Enum.at(&1, idx))
            new_fs = %{fs | records: sorted}
            state = State.set_file_state(state, queue_name, new_fs)
            {:ok, :none, State.set_error(state, 0)}
        end

      :error ->
        {:ok, :none, State.set_error(state, 2)}
    end
  end

  # ── Window Event Functions ──

  defp do_call(:ACCEPTED, [], state) do
    case State.get_var(state, :__ACCEPTED__) do
      {:ok, val} -> {:ok, val, state}
      :error -> {:ok, 0, state}
    end
  end

  defp do_call(:CHOICE, [control_ref], state) do
    name =
      case control_ref do
        {:control_ref, n} -> n
        _ -> nil
      end

    if name do
      key = :"__CHOICE__#{name}"

      case State.get_var(state, key) do
        {:ok, val} -> {:ok, val, state}
        :error -> {:ok, 1, state}
      end
    else
      {:ok, 1, state}
    end
  end

  defp do_call(:SELECT, [_control], state), do: {:ok, :none, state}

  defp do_call(:SELECT, [control_ref, index_expr], state) do
    {index, state} = Eval.eval_expr(index_expr, state)

    case control_ref do
      {:control_ref, name} ->
        key = :"__CHOICE__#{name}"
        {:ok, :none, State.set_var(state, key, index)}

      _ ->
        {:ok, :none, state}
    end
  end

  defp do_call(:BEEP, [], state), do: {:ok, :none, state}
  defp do_call(:DISPLAY, [], state), do: {:ok, :none, state}

  defp do_call(:FORMAT, [value_expr, _picture_expr], state) do
    {value, state} = Eval.eval_expr(value_expr, state)
    {:ok, Eval.to_string_val(value), state}
  end

  # ── Not a builtin ──

  defp do_call(_name, _args, _state), do: :not_builtin

  # ── Helpers ──

  defp eval_args(args, state) do
    Enum.map_reduce(args, state, fn arg, acc ->
      Eval.eval_expr(arg, acc)
    end)
  end

  defp get_file_driver(state, file_name) do
    case State.get_var(state, {:file_driver, file_name}) do
      {:ok, driver} -> driver
      :error -> :memory
    end
  end

  defp resolve_key_ref(key_ref, prefix) do
    case State.parse_prefixed_name(key_ref) do
      {:prefixed, ^prefix, key_name} -> {key_name, key_name}
      _ -> {key_ref, key_ref}
    end
  end

  defp find_key_def(keys, key_name) do
    case Enum.find(keys, fn {name, _fields} -> name == key_name end) do
      nil -> :error
      key -> {:ok, key}
    end
  end

  defp get_key_values(key_fields, %FileState{fields: fields, buffer: buffer}) do
    Enum.map(key_fields, fn kf ->
      field_name =
        case String.split(Atom.to_string(kf), ":") do
          [_, name] -> String.to_atom(name)
          _ -> kf
        end

      case Enum.find_index(fields, fn {:field, n, _, _} -> n == field_name end) do
        nil -> nil
        idx -> Enum.at(buffer, idx)
      end
    end)
  end

  defp error_message(0), do: ""
  defp error_message(2), do: "File not found"
  defp error_message(33), do: "Record not found"
  defp error_message(47), do: "Invalid key"
  defp error_message(_), do: "Unknown error"
end
