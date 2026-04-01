defmodule ClarionSim.ErlogParser do
  @moduledoc """
  Wraps the Erlog Prolog engine to run the DCG Clarion parser.

  Loads the Prolog parser file from priv/prolog/ and provides
  a clean Elixir API for parsing Clarion source code.
  """

  @doc """
  Create a new Erlog parser instance with the grammar loaded.
  Returns {:ok, erlog_state} or {:error, reason}.
  """
  def new do
    case :erlog.new() do
      {:ok, st} ->
        parser_file = parser_path()

        case :erlog.consult(String.to_charlist(parser_file), st) do
          {:ok, st} -> {:ok, st}
          {:error, reason} -> {:error, {:consult_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:erlog_init_failed, reason}}
    end
  end

  @doc """
  Parse Clarion source code into a simple AST.

  The source is converted to character codes and passed to the Prolog
  DCG parser. Returns {:ok, ast} or {:error, reason}.
  """
  def parse(erlog_state, source) when is_binary(source) do
    codes = String.to_charlist(source)
    parse_codes(erlog_state, codes)
  end

  def parse(erlog_state, source) when is_atom(source) do
    parse(erlog_state, Atom.to_string(source))
  end

  @doc """
  Parse from character codes directly.
  """
  def parse_codes(erlog_state, codes) when is_list(codes) do
    # Build the goal: parse_clarion_codes(Codes, AST)
    # Use a fresh variable for AST
    goal = {:parse_clarion_codes, codes, {:erlog_var, :AST}}

    case :erlog.prove(goal, erlog_state) do
      {{:succeed, bindings}, _new_state} ->
        ast = lookup_binding(bindings, :AST)
        {:ok, normalize_ast(ast)}

      {:fail, _new_state} ->
        {:error, :parse_failed}

      {:error, reason} ->
        {:error, {:prove_failed, reason}}
    end
  end

  @doc """
  Parse a file from disk.
  """
  def parse_file(erlog_state, filename) do
    case File.read(filename) do
      {:ok, content} -> parse(erlog_state, content)
      {:error, reason} -> {:error, {:file_read_failed, reason}}
    end
  end

  # ── Private helpers ──

  defp parser_path do
    case :code.priv_dir(:clarion_sim) do
      {:error, _} ->
        # Fallback for development
        Path.join([File.cwd!(), "priv", "prolog", "clarion_parser.pl"])

      dir ->
        Path.join([List.to_string(dir), "prolog", "clarion_parser.pl"])
    end
  end

  defp lookup_binding(bindings, var_name) do
    # Erlog bindings format may vary — handle common formats
    case bindings do
      list when is_list(list) ->
        case List.keyfind(list, var_name, 0) do
          {^var_name, value} -> value
          nil -> nil
        end

      map when is_map(map) ->
        Map.get(map, var_name)

      _ ->
        nil
    end
  end

  @doc """
  Normalize an Erlog AST term into the Elixir representation
  expected by the AST bridge.

  Erlog represents compound terms as tuples: f(a,b) → {f, a, b}
  This function converts them to tagged tuples matching our conventions.
  """
  def normalize_ast(term) do
    case term do
      # Already an Elixir-friendly term
      t when is_atom(t) -> t
      t when is_integer(t) -> t
      t when is_float(t) -> t

      # Lists
      t when is_list(t) -> Enum.map(t, &normalize_ast/1)

      # Compound terms from Erlog — tuples with functor as first element
      t when is_tuple(t) ->
        list = Tuple.to_list(t)
        normalized = Enum.map(list, &normalize_ast/1)
        List.to_tuple(normalized)

      other ->
        other
    end
  end
end
