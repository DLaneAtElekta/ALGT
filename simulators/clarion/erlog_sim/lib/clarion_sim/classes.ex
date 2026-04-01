defmodule ClarionSim.Classes do
  @moduledoc """
  Class and instance management — replaces simulator_classes.pl.

  Handles class definitions, instance creation, property access,
  method lookup with inheritance.
  """

  alias ClarionSim.State

  @doc "Register a class definition in the state."
  def init_class(state, name, parent, attrs, members) do
    class_def = %{name: name, parent: parent, attrs: attrs, members: members}
    %{state | classes: Map.put(state.classes, name, class_def)}
  end

  @doc "Get a class definition by name."
  def get_class_def(%State{} = state, class_name) do
    Map.fetch(state.classes, class_name)
  end

  @doc "Create a new instance of a class with default property values."
  def create_instance(%State{} = state, class_name) do
    case get_class_def(state, class_name) do
      {:ok, class_def} ->
        inherited = get_inherited_props(state, class_def.parent)
        own = get_class_props(class_def.members)
        {:ok, {:instance, class_name, inherited ++ own}}

      :error ->
        {:error, {:undefined_class, class_name}}
    end
  end

  @doc "Get a property value from an instance."
  def get_instance_prop({:instance, _, props}, prop_name) do
    case List.keyfind(props, prop_name, 0) do
      {_, value} -> {:ok, value}
      nil -> :error
    end
  end

  @doc "Set a property value on an instance, returning the updated instance."
  def set_instance_prop({:instance, class, props}, prop_name, value) do
    new_props = List.keystore(props, prop_name, 0, {prop_name, value})
    {:instance, class, new_props}
  end

  @doc "Find a method implementation by walking the class hierarchy."
  def find_method_impl(%State{} = state, class_name, method_name) do
    # Check own methods
    case Map.fetch(state.procs, {:method, class_name, method_name}) do
      {:ok, method_impl} ->
        {:ok, method_impl}

      :error ->
        # Try parent class
        case get_class_def(state, class_name) do
          {:ok, %{parent: parent}} when not is_nil(parent) ->
            find_method_impl(state, parent, method_name)

          _ ->
            :error
        end
    end
  end

  @doc "Get inherited properties from a parent class chain."
  def get_inherited_props(_state, nil), do: []

  def get_inherited_props(state, parent_name) do
    case get_class_def(state, parent_name) do
      {:ok, class_def} ->
        grand_props = get_inherited_props(state, class_def.parent)
        parent_props = get_class_props(class_def.members)
        grand_props ++ parent_props

      :error ->
        []
    end
  end

  @doc "Extract property definitions from class members."
  def get_class_props(members) do
    Enum.flat_map(members, fn
      {:property, name, type, size} ->
        [{name, State.default_value(type, size)}]

      _ ->
        []
    end)
  end
end
