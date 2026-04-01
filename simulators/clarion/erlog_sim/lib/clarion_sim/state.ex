defmodule ClarionSim.State do
  @moduledoc """
  Simulator state — immutable struct threaded through execution.

  Mirrors the Prolog 9-tuple:
    state(Vars, Procs, Output, Files, ErrorCode, Classes, Self, UIState, Continuation)
  """

  alias ClarionSim.UI.Types, as: UITypes

  defstruct vars: %{},
            procs: %{},
            output: [],
            files: %{},
            error_code: 0,
            classes: %{},
            self: nil,
            ui_state: nil,
            continuation: nil,
            map_protos: []

  @type t :: %__MODULE__{
          vars: %{atom() => term()},
          procs: %{atom() => procedure()},
          output: [term()],
          files: %{atom() => ClarionSim.Storage.FileState.t()},
          error_code: non_neg_integer(),
          classes: %{atom() => class_def()},
          self: self_context() | nil,
          ui_state: UITypes.ui_state() | nil,
          continuation: term() | nil,
          map_protos: [map_proto()]
        }

  @type procedure :: %{
          name: atom(),
          params: [param()],
          locals: [local_var()],
          body: [term()]
        }

  @type param :: {atom(), atom()} | {atom(), atom(), :optional, term()}
  @type local_var :: {atom(), atom(), term()}
  @type class_def :: %{name: atom(), parent: atom() | nil, attrs: [term()], members: [term()]}
  @type self_context :: %{var_name: atom(), class: atom(), parent: atom() | nil}
  @type map_proto :: term()

  @doc "Create an empty state with default UI state."
  def empty do
    %__MODULE__{ui_state: UITypes.empty_ui_state()}
  end

  # ── Variable Operations ──

  def get_var(%__MODULE__{} = state, name) when is_atom(name) do
    case parse_prefixed_name(name) do
      {:prefixed, prefix, field} -> get_prefixed_var(state, prefix, field)
      :simple -> Map.fetch(state.vars, name)
    end
  end

  def set_var(%__MODULE__{} = state, name, value) when is_atom(name) do
    case parse_prefixed_name(name) do
      {:prefixed, prefix, field} -> set_prefixed_var(state, prefix, field, value)
      :simple -> %{state | vars: Map.put(state.vars, name, value)}
    end
  end

  @doc "Parse a colon-prefixed name like :'Cust:ID' into {prefix, field}."
  def parse_prefixed_name(name) when is_atom(name) do
    str = Atom.to_string(name)

    case String.split(str, [":", "."], parts: 2) do
      [prefix, field] when prefix != "" and field != "" ->
        {:prefixed, String.to_atom(prefix), String.to_atom(field)}

      _ ->
        :simple
    end
  end

  defp get_prefixed_var(state, prefix, field) do
    cond do
      # Try file by prefix
      file_state = find_file_by_prefix(state, prefix) ->
        if field == :Record do
          {:ok, file_state.buffer}
        else
          ClarionSim.Storage.FileState.get_buffer_field(file_state, field)
        end

      # Try file by name
      Map.has_key?(state.files, prefix) ->
        file_state = state.files[prefix]

        if field == :Record do
          {:ok, file_state.buffer}
        else
          ClarionSim.Storage.FileState.get_buffer_field(file_state, field)
        end

      # Try instance property
      match?({:ok, {:instance, _, _}}, Map.fetch(state.vars, prefix)) ->
        {:ok, {:instance, _class, props}} = Map.fetch(state.vars, prefix)

        case List.keyfind(props, field, 0) do
          {^field, value} -> {:ok, value}
          nil -> :error
        end

      # Try group field
      true ->
        get_group_field(state, prefix, field)
    end
  end

  defp set_prefixed_var(state, prefix, field, value) do
    cond do
      file_state = find_file_by_prefix(state, prefix) ->
        if field == :Record do
          state
        else
          new_fs = ClarionSim.Storage.FileState.set_buffer_field(file_state, field, value)
          %{state | files: Map.put(state.files, file_state.name, new_fs)}
        end

      Map.has_key?(state.files, prefix) ->
        file_state = state.files[prefix]

        if field == :Record do
          state
        else
          new_fs = ClarionSim.Storage.FileState.set_buffer_field(file_state, field, value)
          %{state | files: Map.put(state.files, prefix, new_fs)}
        end

      match?({:ok, {:instance, _, _}}, Map.fetch(state.vars, prefix)) ->
        {:ok, {:instance, class, props}} = Map.fetch(state.vars, prefix)
        new_props = List.keystore(props, field, 0, {field, value})
        set_var(state, prefix, {:instance, class, new_props})

      true ->
        set_group_field(state, prefix, field, value)
    end
  end

  def find_file_by_prefix(state, prefix) do
    Enum.find_value(state.files, fn {_name, fs} ->
      if fs.prefix == prefix, do: fs
    end)
  end

  defp get_group_field(state, prefix, field) do
    with {:ok, group_name} <- Map.fetch(state.vars, {:group_prefix, prefix}),
         {:ok, {:group_val, _pfx, fields, values}} <- Map.fetch(state.vars, group_name) do
      case field_index(fields, field) do
        {:ok, idx} -> {:ok, Enum.at(values, idx)}
        :error -> :error
      end
    else
      _ -> :error
    end
  end

  defp set_group_field(state, prefix, field, value) do
    with {:ok, group_name} <- Map.fetch(state.vars, {:group_prefix, prefix}),
         {:ok, {:group_val, pfx, fields, values}} <- Map.fetch(state.vars, group_name),
         {:ok, idx} <- field_index(fields, field) do
      new_values = List.replace_at(values, idx, value)
      set_var(state, group_name, {:group_val, pfx, fields, new_values})
    else
      _ -> state
    end
  end

  defp field_index(fields, name) do
    case Enum.find_index(fields, fn {:field, n, _, _} -> n == name end) do
      nil -> :error
      idx -> {:ok, idx}
    end
  end

  # ── Procedure Lookup ──

  def get_proc(%__MODULE__{} = state, name) do
    case Map.fetch(state.procs, name) do
      {:ok, _} = result ->
        result

      :error ->
        # Try NAME alias
        case resolve_name_alias(state, name) do
          {:ok, clarion_name} -> Map.fetch(state.procs, clarion_name)
          :error -> :error
        end
    end
  end

  def resolve_name_alias(state, alias_name) do
    Enum.find_value(state.map_protos, :error, fn
      %{attrs: attrs, name: cname} ->
        if Enum.any?(attrs, &match?({:name, ^alias_name}, &1)), do: {:ok, cname}

      _ ->
        nil
    end)
  end

  def is_external_proc?(state, name) do
    Enum.any?(state.map_protos, fn
      %{type: :external, name: ^name} -> true
      %{type: :external, attrs: attrs} -> Enum.any?(attrs, &match?({:name, ^name}, &1))
      _ -> false
    end)
  end

  # ── Output ──

  def add_output(%__MODULE__{} = state, item) do
    %{state | output: [item | state.output]}
  end

  def get_output_list(%__MODULE__{} = state) do
    Enum.reverse(state.output)
  end

  # ── Error ──

  def set_error(%__MODULE__{} = state, code) do
    %{state | error_code: code}
  end

  # ── Self Context ──

  def set_self(%__MODULE__{} = state, context) do
    %{state | self: context}
  end

  # ── File State ──

  def get_file_state(%__MODULE__{} = state, name) do
    Map.fetch(state.files, name)
  end

  def set_file_state(%__MODULE__{} = state, name, file_state) do
    %{state | files: Map.put(state.files, name, file_state)}
  end

  # ── UI State ──

  def get_ui_state(%__MODULE__{} = state), do: state.ui_state

  def set_ui_state(%__MODULE__{} = state, ui_state) do
    %{state | ui_state: ui_state}
  end

  # ── Default Values ──

  def default_value(type, _size \\ nil) do
    case type do
      t when t in ~w(STRING CSTRING PSTRING)a -> ""
      t when t in ~w(REAL SREAL)a -> 0.0
      _ -> 0
    end
  end
end
