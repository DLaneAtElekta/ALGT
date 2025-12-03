%============================================================
% tracer_tests.pl - Unit Tests for Execution Tracer
%
% Tests for all tracer modules.
%============================================================

:- module(tracer_tests, [run_tracer_tests/0]).

:- use_module(library(plunit)).

:- use_module(trace_core).
:- use_module(trace_events).
:- use_module(trace_retrieval).
:- use_module(execution_graph).
:- use_module(graph_export).
:- use_module(ml_export).

%% run_tracer_tests is det.
%
% Run all tracer tests.

run_tracer_tests :-
    run_tests([
        trace_core_tests,
        trace_events_tests,
        trace_retrieval_tests,
        execution_graph_tests,
        graph_export_tests
    ]).

%------------------------------------------------------------
% Trace Core Tests
%------------------------------------------------------------

:- begin_tests(trace_core_tests).

test(trace_control) :-
    clear_trace,
    \+ is_tracing,
    start_trace,
    is_tracing,
    trace_event(test, data{value: 1}),
    stop_trace(Trace),
    \+ is_tracing,
    Trace.summary.total_events > 0.

test(trace_options) :-
    start_trace(trace_options{
        capture_vars: true,
        capture_reads: true,
        capture_statements: false,
        capture_branches: true,
        capture_calls: true,
        capture_file_ops: true,
        max_events: 1000
    }),
    is_tracing,
    stop_trace(_).

test(clear_trace) :-
    start_trace,
    trace_event(test, data{value: 1}),
    clear_trace,
    \+ is_tracing.

:- end_tests(trace_core_tests).

%------------------------------------------------------------
% Trace Events Tests
%------------------------------------------------------------

:- begin_tests(trace_events_tests).

test(trace_statement) :-
    start_trace,
    trace_statement_start(assign, test_ast),
    trace_statement_end(assign, normal),
    stop_trace(Trace),
    length(Trace.events, 2).

test(trace_branch) :-
    start_trace,
    trace_branch(if, 'X > 0', true, true),
    stop_trace(Trace),
    length(Trace.events, 1).

test(trace_var_assign) :-
    start_trace,
    trace_var_assign('X', 0, 42),
    stop_trace(Trace),
    length(Trace.events, 1).

test(trace_proc_calls) :-
    start_trace,
    trace_proc_enter('TestProc', [1, 2, 3]),
    get_call_stack(Stack1),
    Stack1 = [proc('TestProc')],
    trace_proc_exit('TestProc', ok),
    get_call_stack(Stack2),
    Stack2 = [],
    stop_trace(_).

test(trace_loop) :-
    start_trace,
    trace_loop_start(while, cond('X > 0')),
    trace_loop_iteration(while, 1, true),
    trace_loop_iteration(while, 2, true),
    trace_loop_end(while, condition_false),
    stop_trace(Trace),
    length(Trace.events, 4).

:- end_tests(trace_events_tests).

%------------------------------------------------------------
% Trace Retrieval Tests
%------------------------------------------------------------

:- begin_tests(trace_retrieval_tests).

test(get_trace) :-
    start_trace,
    trace_event(statement_start, stmt{type: assign, ast: test}),
    trace_event(var_assign, var{name: 'X', old: 0, new: 42}),
    get_trace(Events),
    length(Events, 2),
    stop_trace(_).

test(get_execution_path) :-
    start_trace,
    trace_event(statement_start, stmt{type: assign, ast: test}),
    trace_event(branch_decision, branch{context: if, condition: c1, value: true, branch_taken: true}),
    trace_event(proc_enter, call{name: 'Foo', args: []}),
    get_execution_path(Path),
    Path = [stmt(assign), branch(if, true), enter('Foo')],
    stop_trace(_).

test(branch_decisions) :-
    start_trace,
    trace_event(branch_decision, branch{context: if, condition: c1, value: true, branch_taken: true}),
    trace_event(branch_decision, branch{context: if, condition: c2, value: false, branch_taken: false}),
    get_branch_decisions(Decisions),
    length(Decisions, 2),
    stop_trace(_).

test(variable_history) :-
    start_trace,
    trace_event(var_assign, var{name: 'Counter', old: 0, new: 1}),
    trace_event(var_assign, var{name: 'Other', old: 0, new: 5}),
    trace_event(var_assign, var{name: 'Counter', old: 1, new: 2}),
    get_variable_history('Counter', History),
    length(History, 2),
    stop_trace(_).

test(trace_summary) :-
    start_trace,
    trace_event(statement_start, stmt{type: assign, ast: test}),
    trace_event(branch_decision, branch{context: if, condition: c1, value: true, branch_taken: true}),
    trace_event(branch_decision, branch{context: if, condition: c2, value: false, branch_taken: false}),
    trace_summary(Summary),
    Summary.total_events = 3,
    Summary.branch_stats.total = 2,
    Summary.branch_stats.true_branches = 1,
    stop_trace(_).

:- end_tests(trace_retrieval_tests).

%------------------------------------------------------------
% Execution Graph Tests
%------------------------------------------------------------

:- begin_tests(execution_graph_tests).

test(graph_creation) :-
    start_trace,
    init_graph,
    % Should have root node
    get_execution_graph(Graph),
    Graph.metadata.node_count > 0,
    stop_trace(_).

test(graph_nodes_and_edges) :-
    start_trace,
    init_graph,
    % Manually add nodes to simulate execution
    add_graph_node(assign, assign{var: 'X', value: 10, expr: num(10)}, N1),
    add_graph_node(assign, assign{var: 'Y', value: 20, expr: num(20)}, N2),
    add_graph_node(branch, branch{condition: 'X > Y', value: false}, _N3),
    set_current_node(N1),  % Go back to N1 for data flow
    record_var_write('X', N1),
    record_var_write('Y', N2),
    get_execution_graph(Graph),
    Graph.metadata.node_count >= 4,  % root + 3 nodes
    Graph.metadata.control_edges >= 3,  % root->N1->N2->N3
    stop_trace(_).

test(data_flow_tracking) :-
    start_trace,
    init_graph,
    % Simulate: X = 10; Y = X + 5
    add_graph_node(assign, assign{var: 'X', value: 10}, N1),
    record_var_write('X', N1),
    set_current_node(N1),
    add_graph_node(assign, assign{var: 'Y', value: 15}, N2),
    record_var_read('X', N2),  % Y reads X
    record_var_write('Y', N2),
    get_data_flow(DataFlow),
    % Should have one data edge from X's write to Y's read
    length(DataFlow, 1),
    stop_trace(_).

test(high_level_helpers) :-
    start_trace,
    init_graph,
    graph_node_for_assignment('X', 10, num(10), N1),
    N1 > 0,
    graph_node_for_branch('X > 5', true, N2),
    N2 > N1,
    get_execution_graph(Graph),
    Graph.metadata.node_count >= 3,
    stop_trace(_).

:- end_tests(execution_graph_tests).

%------------------------------------------------------------
% Graph Export Tests
%------------------------------------------------------------

:- begin_tests(graph_export_tests).

test(graph_to_dot_export) :-
    start_trace,
    init_graph,
    add_graph_node(assign, assign{var: 'X', value: 10}, _),
    get_execution_graph(Graph),
    graph_to_dot(Graph, DotString),
    sub_string(DotString, _, _, _, "digraph"),
    stop_trace(_).

test(graph_to_json_export) :-
    start_trace,
    init_graph,
    add_graph_node(assign, assign{var: 'X', value: 10}, _),
    get_execution_graph(Graph),
    graph_to_json(Graph, JsonString),
    sub_string(JsonString, _, _, _, "\"nodes\""),
    sub_string(JsonString, _, _, _, "\"edges\""),
    stop_trace(_).

:- end_tests(graph_export_tests).
