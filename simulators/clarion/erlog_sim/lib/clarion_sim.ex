defmodule ClarionSim do
  @moduledoc """
  Clarion Simulator — Erlog/Elixir implementation.

  Combines an Erlog-based DCG parser with an Elixir execution engine
  and protocol-based storage/UI backends.

  ## Architecture

      .clw source → Erlog DCG Parser → Simple AST → AST Bridge → Modular AST → Elixir Simulator
                                                                                      ↓
                                                                        Storage Protocol (Memory/CSV/ODBC)
                                                                        UI Protocol (Simulation/...)

  ## Usage

      # One-shot procedure execution
      {:ok, result} = ClarionSim.exec_procedure(source, :MathAdd, [10, 20])

      # Stateful session (DLL simulation)
      {:ok, session} = ClarionSim.init_session(source)
      {:ok, result, session} = ClarionSim.call_procedure(session, :SSOpen, [])
      {:ok, result, session} = ClarionSim.call_procedure(session, :SSAddReading, [1, 100, 50])

      # Full program execution with event injection
      {:ok, result} = ClarionSim.exec_program(source, [set: {:SensorID, 1}, 1])
  """

  alias ClarionSim.{ErlogParser, ASTBridge, Simulator, State, Eval}

  @doc """
  Parse Clarion source code and return the modular AST.

  Uses the Erlog DCG parser, then bridges to the modular format.
  """
  def parse(source) do
    with {:ok, erlog} <- ErlogParser.new(),
         {:ok, simple_ast} <- ErlogParser.parse(erlog, source) do
      {:ok, ASTBridge.bridge(simple_ast)}
    end
  end

  @doc """
  Run source code and return the final state.
  """
  def run_source(source) do
    case parse(source) do
      {:ok, mod_ast} -> {:ok, Simulator.run_ast(mod_ast)}
      error -> error
    end
  end

  @doc """
  Execute a named procedure (stateless, one-shot).
  """
  def exec_procedure(source, proc_name, args) do
    with {:ok, session} <- init_session(source) do
      call_procedure(session, proc_name, args)
    end
  end

  @doc """
  Initialize a stateful session for multi-call DLL simulation.
  """
  def init_session(source) do
    case parse(source) do
      {:ok, {:program, {:map, map_decls}, global_decls, _code, procedures}} ->
        state = State.empty()
        state = Simulator.init_map_protos(map_decls, state)
        state = Simulator.init_procedures(procedures, state)
        state = Simulator.init_globals(global_decls, state)
        {:ok, state}

      error ->
        error
    end
  end

  @doc """
  Call a procedure on an existing session. Returns {:ok, result, new_session}.
  """
  def call_procedure(%State{} = session, proc_name, args) do
    arg_exprs = Enum.map(args, &wrap_arg/1)
    {result, new_session} = Simulator.exec_call(proc_name, arg_exprs, session)
    {:ok, result, new_session}
  end

  @doc """
  Execute a PROGRAM with event simulation (for GUI testing).
  """
  def exec_program(source, events) do
    case parse(source) do
      {:ok, {:program, {:map, map_decls}, global_decls, {:code, main_body}, procedures}} ->
        state = State.empty()
        state = Simulator.init_map_protos(map_decls, state)
        state = Simulator.init_procedures(procedures, state)
        state = Simulator.init_globals(global_decls, state)

        # Set up event queue
        ui = state.ui_state
        state = State.set_ui_state(state, %{ui | event_queue: events})

        {_control, final_state} = Simulator.exec_statements(main_body, state)

        result =
          case State.get_var(final_state, :Result) do
            {:ok, val} -> val
            :error -> 0
          end

        {:ok, result, final_state}

      error ->
        error
    end
  end

  @doc """
  Get the output messages accumulated during execution.
  """
  def get_output(%State{} = state) do
    State.get_output_list(state)
  end

  @doc """
  Get a variable value from a session state.
  """
  def get_var(%State{} = state, name) do
    State.get_var(state, name)
  end

  # ── Private ──

  defp wrap_arg(n) when is_integer(n), do: {:number, n}
  defp wrap_arg(n) when is_float(n), do: {:number, n}
  defp wrap_arg(s) when is_binary(s), do: {:string, s}
  defp wrap_arg(a) when is_atom(a), do: {:string, Atom.to_string(a)}
  defp wrap_arg(expr), do: expr
end
