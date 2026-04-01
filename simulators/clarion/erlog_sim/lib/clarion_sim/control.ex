defmodule ClarionSim.Control do
  @moduledoc """
  Control flow helpers — replaces simulator_control.pl.

  Provides routine lookup, CASE matching, and event phase management.
  """

  alias ClarionSim.State

  @doc "Look up a routine by name in the state's procedures."
  def get_routine(%State{} = state, name) do
    case Map.fetch(state.procs, {:routine, name}) do
      {:ok, body} -> {:ok, body}
      :error -> {:error, {:undefined_routine, name}}
    end
  end

  @doc """
  Match a value against a list of case branches.
  Returns {:match, body} or :else if no match found.
  """
  def match_case(_value, []), do: :else

  def match_case(value, [{:case_of, {:range, start_val, end_val}, body} | rest]) do
    if is_number(value) and value >= start_val and value <= end_val do
      {:match, body}
    else
      match_case(value, rest)
    end
  end

  def match_case(value, [{:case_of, case_val, body} | rest]) do
    if value == case_val do
      {:match, body}
    else
      match_case(value, rest)
    end
  end

  @doc "Event phase state machine for ACCEPT loop."
  def next_phase(:open_window), do: :close_window
  def next_phase(:close_window), do: :done
  def next_phase(:done), do: :done
end
