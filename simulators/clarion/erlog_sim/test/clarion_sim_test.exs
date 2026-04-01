defmodule ClarionSimTest do
  use ExUnit.Case, async: true

  alias ClarionSim.{State, Eval, ASTBridge, Simulator, Control, Classes}
  alias ClarionSim.Storage.{FileState, Memory, Backend, Dispatcher}
  alias ClarionSim.UI.{Simulation, Types}

  # ═══════════════════════════════════════════════════════════
  # State Tests
  # ═══════════════════════════════════════════════════════════

  describe "State" do
    test "empty state has defaults" do
      state = State.empty()
      assert state.vars == %{}
      assert state.error_code == 0
      assert state.ui_state != nil
    end

    test "get/set variable" do
      state = State.empty()
      state = State.set_var(state, :X, 42)
      assert {:ok, 42} = State.get_var(state, :X)
    end

    test "undefined variable returns :error" do
      state = State.empty()
      assert :error = State.get_var(state, :Missing)
    end

    test "parse_prefixed_name" do
      assert {:prefixed, :Cust, :ID} = State.parse_prefixed_name(:"Cust:ID")
      assert :simple = State.parse_prefixed_name(:X)
    end

    test "add_output accumulates in order" do
      state = State.empty()
      state = State.add_output(state, {:message, "hello"})
      state = State.add_output(state, {:message, "world"})
      assert [{:message, "hello"}, {:message, "world"}] = State.get_output_list(state)
    end

    test "set_error and get error_code" do
      state = State.empty()
      state = State.set_error(state, 33)
      assert state.error_code == 33
    end

    test "default values by type" do
      assert State.default_value(:LONG) == 0
      assert State.default_value(:STRING) == ""
      assert State.default_value(:REAL) == 0.0
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Expression Evaluation Tests
  # ═══════════════════════════════════════════════════════════

  describe "Eval" do
    test "number literal" do
      state = State.empty()
      assert {42, _} = Eval.eval_expr({:number, 42}, state)
    end

    test "string literal" do
      state = State.empty()
      assert {"hello", _} = Eval.eval_expr({:string, "hello"}, state)
    end

    test "variable lookup" do
      state = State.empty() |> State.set_var(:X, 10)
      assert {10, _} = Eval.eval_expr({:var, :X}, state)
    end

    test "arithmetic binops" do
      assert Eval.eval_binop(:+, 3, 4) == 7
      assert Eval.eval_binop(:-, 10, 3) == 7
      assert Eval.eval_binop(:*, 3, 4) == 12
      assert Eval.eval_binop(:/, 10, 3) == 3
      assert Eval.eval_binop(:%, 10, 3) == 1
    end

    test "integer division" do
      assert Eval.eval_binop(:/, 7, 2) == 3
    end

    test "string concatenation with &" do
      assert Eval.eval_binop(:&, "hello", " world") == "hello world"
    end

    test "comparison operators" do
      assert Eval.eval_binop(:=, 5, 5) == 1
      assert Eval.eval_binop(:=, 5, 6) == 0
      assert Eval.eval_binop(:<>, 5, 6) == 1
      assert Eval.eval_binop(:<, 3, 5) == 1
      assert Eval.eval_binop(:>, 5, 3) == 1
    end

    test "logical operators" do
      assert Eval.eval_binop(:and, 1, 1) == 1
      assert Eval.eval_binop(:and, 1, 0) == 0
      assert Eval.eval_binop(:or, 0, 1) == 1
      assert Eval.eval_binop(:or, 0, 0) == 0
    end

    test "truthiness" do
      assert Eval.truthy?(1)
      assert Eval.truthy?(42)
      assert Eval.truthy?("hello")
      refute Eval.truthy?(0)
      refute Eval.truthy?("")
      refute Eval.truthy?(nil)
    end

    test "nested binop expression" do
      state = State.empty()
      # (3 + 4) * 2
      expr = {:binop, :*, {:binop, :+, {:number, 3}, {:number, 4}}, {:number, 2}}
      assert {14, _} = Eval.eval_expr(expr, state)
    end

    test "NOT expression" do
      state = State.empty()
      assert {0, _} = Eval.eval_expr({:not, {:number, 1}}, state)
      assert {1, _} = Eval.eval_expr({:not, {:number, 0}}, state)
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Control Flow Tests
  # ═══════════════════════════════════════════════════════════

  describe "Control" do
    test "match_case with direct value" do
      cases = [
        {:case_of, {:number, 1}, [:body_1]},
        {:case_of, {:number, 2}, [:body_2]}
      ]

      assert {:match, [:body_1]} = Control.match_case(1, [{:case_of, 1, [:body_1]}, {:case_of, 2, [:body_2]}])
    end

    test "match_case returns :else when no match" do
      assert :else = Control.match_case(99, [{:case_of, 1, [:body_1]}])
    end

    test "match_case with range" do
      cases = [{:case_of, {:range, 0, 10}, [:in_range]}]
      assert {:match, [:in_range]} = Control.match_case(5, cases)
      assert :else = Control.match_case(15, cases)
    end

    test "next_phase state machine" do
      assert Control.next_phase(:open_window) == :close_window
      assert Control.next_phase(:close_window) == :done
      assert Control.next_phase(:done) == :done
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Storage Protocol Tests
  # ═══════════════════════════════════════════════════════════

  describe "Storage.Memory" do
    setup do
      fields = [
        {:field, :ID, :LONG, :none},
        {:field, :Value, :LONG, :none},
        {:field, :Name, :STRING, :none}
      ]

      fs = FileState.new(:TestFile, :TF, [{:IDKey, [:ID]}], fields)
      %{fs: fs, backend: %Memory{}}
    end

    test "open sets position and is_open", %{fs: fs, backend: backend} do
      {:ok, opened} = Backend.open(backend, fs)
      assert opened.is_open == true
      assert opened.position == -1
    end

    test "add appends record", %{fs: fs, backend: backend} do
      {:ok, fs} = Backend.open(backend, fs)
      fs = %{fs | buffer: [1, 100, "test"]}
      {:ok, fs} = Backend.add(backend, fs)
      assert length(fs.records) == 1
      assert hd(fs.records) == [1, 100, "test"]
    end

    test "next advances through records", %{fs: fs, backend: backend} do
      {:ok, fs} = Backend.open(backend, fs)
      fs = %{fs | buffer: [1, 100, "first"]}
      {:ok, fs} = Backend.add(backend, fs)
      fs = %{fs | buffer: [2, 200, "second"]}
      {:ok, fs} = Backend.add(backend, fs)

      {:ok, fs} = Backend.set(backend, fs)
      {:ok, fs} = Backend.next(backend, fs)
      assert fs.buffer == [1, 100, "first"]
      assert fs.position == 0

      {:ok, fs} = Backend.next(backend, fs)
      assert fs.buffer == [2, 200, "second"]
      assert fs.position == 1
    end

    test "delete removes record", %{fs: fs, backend: backend} do
      {:ok, fs} = Backend.open(backend, fs)
      fs = %{fs | buffer: [1, 100, "first"]}
      {:ok, fs} = Backend.add(backend, fs)
      fs = %{fs | buffer: [2, 200, "second"]}
      {:ok, fs} = Backend.add(backend, fs)

      {:ok, fs} = Backend.set(backend, fs)
      {:ok, fs} = Backend.next(backend, fs)
      {:ok, fs} = Backend.delete(backend, fs)
      assert Backend.records(backend, fs) == 1
    end

    test "empty clears all records", %{fs: fs, backend: backend} do
      {:ok, fs} = Backend.open(backend, fs)
      fs = %{fs | buffer: [1, 100, "test"]}
      {:ok, fs} = Backend.add(backend, fs)
      {:ok, fs} = Backend.empty(backend, fs)
      assert Backend.records(backend, fs) == 0
    end

    test "records returns count", %{fs: fs, backend: backend} do
      {:ok, fs} = Backend.open(backend, fs)
      assert Backend.records(backend, fs) == 0
      fs = %{fs | buffer: [1, 100, "test"]}
      {:ok, fs} = Backend.add(backend, fs)
      assert Backend.records(backend, fs) == 1
    end
  end

  describe "Storage.Dispatcher" do
    test "routes to memory by default" do
      fields = [{:field, :X, :LONG, :none}]
      fs = FileState.new(:Test, nil, [], fields)
      {:ok, opened} = Dispatcher.open(:memory, fs)
      assert opened.is_open
    end
  end

  # ═══════════════════════════════════════════════════════════
  # UI Protocol Tests
  # ═══════════════════════════════════════════════════════════

  describe "UI.Simulation" do
    test "open_window adds to stack" do
      state = State.empty()
      backend = %Simulation{}
      window_def = {:window, :TestWin, "Test", []}
      {:ok, state} = ClarionSim.UI.Backend.open_window(backend, window_def, state)
      assert length(state.ui_state.windows) == 1
      assert hd(state.ui_state.windows).name == :TestWin
    end

    test "close_window removes from stack" do
      state = State.empty()
      backend = %Simulation{}
      {:ok, state} = ClarionSim.UI.Backend.open_window(backend, {:window, :W1, "W1", []}, state)
      {:ok, state} = ClarionSim.UI.Backend.close_window(backend, state)
      assert state.ui_state.windows == []
    end

    test "init and shutdown are no-ops" do
      state = State.empty()
      backend = %Simulation{}
      {:ok, ^state} = ClarionSim.UI.Backend.init(backend, state)
      {:ok, ^state} = ClarionSim.UI.Backend.shutdown(backend, state)
    end
  end

  describe "UI.Dispatcher" do
    test "push and poll events" do
      state = State.empty()
      {:ok, state} = ClarionSim.UI.Dispatcher.push_event(:test_event, state)
      {:ok, state, event} = ClarionSim.UI.Dispatcher.poll_event(state)
      assert event == :test_event
    end

    test "has_events?" do
      state = State.empty()
      refute ClarionSim.UI.Dispatcher.has_events?(state)
      {:ok, state} = ClarionSim.UI.Dispatcher.push_event(:ev, state)
      assert ClarionSim.UI.Dispatcher.has_events?(state)
    end
  end

  # ═══════════════════════════════════════════════════════════
  # AST Bridge Tests
  # ═══════════════════════════════════════════════════════════

  describe "ASTBridge" do
    test "bridges simple expression AST" do
      assert {:number, 42} = ASTBridge.bridge_expr_public({:lit, 42})
      assert {:string, "hello"} = ASTBridge.bridge_expr_public({:lit, :hello})
      assert {:binop, :+, {:number, 1}, {:number, 2}} = ASTBridge.bridge_expr_public({:add, {:lit, 1}, {:lit, 2}})
    end

    test "bridges program structure" do
      simple_ast = {:program, [], [], [{:global, :X, :long, :none}], [], []}

      {:program, {:map, []}, globals, {:code, []}, []} = ASTBridge.bridge(simple_ast)
      assert [{:var, :X, :LONG, :none}] = globals
    end

    test "bridges procedure with params and body" do
      proc = {:procedure, :Add, [{:param, :A, :long}, {:param, :B, :long}], :long,
              [{:local, :Result, :long, :none}],
              [{:assign, :Result, {:add, {:var, :A}, {:var, :B}}}, {:return, {:var, :Result}}]}

      simple_ast = {:program, [], [], [], [], [proc]}
      {:program, _, _, _, procs} = ASTBridge.bridge(simple_ast)
      assert length(procs) == 1
    end

    test "bridges types correctly" do
      assert ASTBridge.bridge_type_public(:long) == :LONG
      assert ASTBridge.bridge_type_public(:cstring) == :CSTRING
      assert ASTBridge.bridge_type_public(:real) == :REAL
      assert ASTBridge.bridge_type_public(:void) == :void
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Simulator Tests
  # ═══════════════════════════════════════════════════════════

  describe "Simulator" do
    test "simple assignment and return" do
      state = State.empty()
      stmts = [
        {:assign, :X, {:number, 42}},
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 42} = State.get_var(state, :X)
    end

    test "if-then branch taken" do
      state = State.empty()
      stmts = [
        {:if, {:number, 1},
         [{:assign, :X, {:number, 10}}],
         [],
         [{:assign, :X, {:number, 20}}]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 10} = State.get_var(state, :X)
    end

    test "if-else branch taken" do
      state = State.empty()
      stmts = [
        {:if, {:number, 0},
         [{:assign, :X, {:number, 10}}],
         [],
         [{:assign, :X, {:number, 20}}]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 20} = State.get_var(state, :X)
    end

    test "loop with break" do
      state = State.empty() |> State.set_var(:Count, 0)
      stmts = [
        {:loop, [
          {:assign_add, :Count, {:number, 1}},
          {:if, {:binop, :>=, {:var, :Count}, {:number, 5}},
           [:break], [], []}
        ]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 5} = State.get_var(state, :Count)
    end

    test "loop_to (FOR loop)" do
      state = State.empty() |> State.set_var(:Sum, 0)
      stmts = [
        {:loop_to, :I, {:number, 1}, {:number, 5}, [
          {:assign_add, :Sum, {:var, :I}}
        ]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 15} = State.get_var(state, :Sum)
    end

    test "loop_while" do
      state = State.empty() |> State.set_var(:N, 10)
      stmts = [
        {:loop_while, {:binop, :>, {:var, :N}, {:number, 0}}, [
          {:assign, :N, {:binop, :-, {:var, :N}, {:number, 3}}}
        ]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      {:ok, n} = State.get_var(state, :N)
      assert n <= 0
    end

    test "case statement" do
      state = State.empty() |> State.set_var(:X, 2)
      stmts = [
        {:case, {:var, :X},
         [
           {:case_of, {:number, 1}, [{:assign, :Result, {:string, "one"}}]},
           {:case_of, {:number, 2}, [{:assign, :Result, {:string, "two"}}]},
           {:case_of, {:number, 3}, [{:assign, :Result, {:string, "three"}}]}
         ],
         [{:assign, :Result, {:string, "other"}}]}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, "two"} = State.get_var(state, :Result)
    end

    test "procedure call with return value" do
      proc = %{
        name: :Double,
        params: [{:LONG, :N}],
        locals: [],
        body: [{:return, {:binop, :*, {:var, :N}, {:number, 2}}}]
      }

      state = State.empty()
      state = %{state | procs: %{Double: proc}}

      stmts = [
        {:assign, :Result, {:call, :Double, [{:number, 7}]}}
      ]

      {:normal, state} = Simulator.exec_statements(stmts, state)
      assert {:ok, 14} = State.get_var(state, :Result)
    end

    test "accept loop processes events" do
      state = State.empty()
      ui = state.ui_state
      state = State.set_ui_state(state, %{ui | event_queue: [{:set, :SensorID, 1}, 1]})
      state = State.set_var(state, {:equate, :CalcBtn}, 1)

      body = [
        {:case, {:call, :ACCEPTED, []},
         [{:case_of, {:control_ref, :CalcBtn}, [{:assign, :Clicked, {:number, 1}}]}],
         []}
      ]

      {:normal, state} = Simulator.exec_statement({:accept, body}, state)
      assert {:ok, 1} = State.get_var(state, :SensorID)
      assert {:ok, 1} = State.get_var(state, :Clicked)
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Classes Tests
  # ═══════════════════════════════════════════════════════════

  describe "Classes" do
    test "init_class and create_instance" do
      state = State.empty()

      state = Classes.init_class(state, :Animal, nil, [],
        [{:property, :Name, :STRING, :none}, {:property, :Age, :LONG, :none}])

      {:ok, instance} = Classes.create_instance(state, :Animal)
      assert {:instance, :Animal, props} = instance
      assert {:"Name", ""} in props
      assert {:"Age", 0} in props
    end

    test "get/set instance property" do
      instance = {:instance, :Animal, [{:Name, "Fido"}, {:Age, 5}]}
      assert {:ok, "Fido"} = Classes.get_instance_prop(instance, :Name)

      updated = Classes.set_instance_prop(instance, :Age, 6)
      assert {:ok, 6} = Classes.get_instance_prop(updated, :Age)
    end

    test "inheritance" do
      state = State.empty()
      state = Classes.init_class(state, :Base, nil, [],
        [{:property, :X, :LONG, :none}])
      state = Classes.init_class(state, :Derived, :Base, [],
        [{:property, :Y, :LONG, :none}])

      {:ok, instance} = Classes.create_instance(state, :Derived)
      {:instance, :Derived, props} = instance
      assert length(props) == 2
    end
  end

  # ═══════════════════════════════════════════════════════════
  # Built-in Function Tests
  # ═══════════════════════════════════════════════════════════

  describe "Builtins" do
    test "UPPER" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:UPPER, [{:string, "hello"}], state)
      assert result == "HELLO"
    end

    test "LOWER" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:LOWER, [{:string, "HELLO"}], state)
      assert result == "hello"
    end

    test "LEN" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:LEN, [{:string, "hello"}], state)
      assert result == 5
    end

    test "ABS" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:ABS, [{:number, -42}], state)
      assert result == 42
    end

    test "SQRT" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:SQRT, [{:number, 9}], state)
      assert result == 3
    end

    test "INSTRING" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:INSTRING, [{:string, "lo"}, {:string, "hello"}], state)
      assert result == 4
    end

    test "SUB" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:SUB, [{:string, "hello"}, {:number, 2}, {:number, 3}], state)
      assert result == "ell"
    end

    test "ERRORCODE" do
      state = State.empty() |> State.set_error(33)
      {:ok, result, _} = ClarionSim.Builtins.call(:ERRORCODE, [], state)
      assert result == 33
    end

    test "CLIP trims trailing spaces" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:CLIP, [{:string, "hello   "}], state)
      assert result == "hello"
    end

    test "LEFT trims leading spaces" do
      state = State.empty()
      {:ok, result, _} = ClarionSim.Builtins.call(:LEFT, [{:string, "   hello"}], state)
      assert result == "hello"
    end
  end

  # ═══════════════════════════════════════════════════════════
  # FileState Tests
  # ═══════════════════════════════════════════════════════════

  describe "FileState" do
    test "create with default buffer" do
      fields = [{:field, :A, :LONG, :none}, {:field, :B, :STRING, :none}]
      fs = FileState.new(:Test, nil, [], fields)
      assert fs.buffer == [0, ""]
    end

    test "get/set buffer field" do
      fields = [{:field, :X, :LONG, :none}, {:field, :Y, :LONG, :none}]
      fs = FileState.new(:Test, nil, [], fields)

      fs = FileState.set_buffer_field(fs, :X, 42)
      assert {:ok, 42} = FileState.get_buffer_field(fs, :X)
      assert {:ok, 0} = FileState.get_buffer_field(fs, :Y)
    end

    test "clear_buffer resets to defaults" do
      fields = [{:field, :X, :LONG, :none}]
      fs = FileState.new(:Test, nil, [], fields)
      fs = FileState.set_buffer_field(fs, :X, 999)
      fs = FileState.clear_buffer(fs)
      assert {:ok, 0} = FileState.get_buffer_field(fs, :X)
    end
  end
end
