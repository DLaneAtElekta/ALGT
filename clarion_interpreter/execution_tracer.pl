%============================================================
% execution_tracer.pl - Execution Trace Capture for Clarion Interpreter
%
% FACADE MODULE - Re-exports all tracer submodules for backward compatibility.
%
% Captures detailed execution traces including:
%   - Statement executions
%   - Branch decisions (IF/CASE/LOOP conditions)
%   - Variable assignments
%   - Procedure/method calls
%   - File/database operations
%
% Usage:
%   ?- start_trace.
%   ?- run_file('example.clw').
%   ?- stop_trace(Trace).
%   ?- get_execution_path(Path).
%
% Module Structure:
%   tracer/trace_core.pl         - Core state and control
%   tracer/trace_events.pl       - Convenience event recording
%   tracer/trace_retrieval.pl    - Query and analysis
%   tracer/execution_graph.pl    - DAG construction
%   tracer/graph_export.pl       - DOT/JSON export
%   tracer/ml_export.pl          - PyTorch-friendly formats
%   tracer/probabilistic_model.pl - PGM/PyMC/Stan
%   tracer/gnn_vae.pl            - GNN-VAE Python generation
%   tracer/tracer_tests.pl       - Unit tests
%============================================================

:- module(execution_tracer, [
    % Trace control (from trace_core)
    start_trace/0,
    start_trace/1,          % start_trace(+Options)
    stop_trace/1,           % stop_trace(-Trace)
    is_tracing/0,
    clear_trace/0,

    % Event recording (from trace_core)
    trace_event/1,          % trace_event(+Event)
    trace_event/2,          % trace_event(+EventType, +Data)

    % Trace retrieval (from trace_retrieval)
    get_trace/1,            % get_trace(-Trace)
    get_execution_path/1,   % get_execution_path(-Path)
    get_branch_decisions/1, % get_branch_decisions(-Decisions)
    get_variable_history/2, % get_variable_history(+VarName, -History)
    get_call_stack/1,       % get_call_stack(-Stack)

    % Trace analysis (from trace_retrieval)
    trace_summary/1,        % trace_summary(-Summary)
    path_to_dot/2,          % path_to_dot(+Trace, -DotString)

    % Execution Graph (from execution_graph)
    get_execution_graph/1,  % get_execution_graph(-Graph)
    graph_to_dot/2,         % graph_to_dot(+Graph, -DotString)
    graph_to_json/2,        % graph_to_json(+Graph, -JsonString)
    get_data_flow/1,        % get_data_flow(-DataFlow) - variable dependencies
    get_control_flow/1,     % get_control_flow(-ControlFlow) - statement sequence

    % Graph node operations (from execution_graph)
    add_graph_node/3,       % add_graph_node(+Type, +Data, -NodeId)
    add_graph_edge/3,       % add_graph_edge(+FromId, +ToId, +EdgeType)
    current_node_id/1,      % current_node_id(-Id)
    set_current_node/1,     % set_current_node(+Id)

    % Data dependency tracking (from execution_graph)
    record_var_write/2,     % record_var_write(+VarName, +NodeId)
    record_var_read/2,      % record_var_read(+VarName, +NodeId)

    % High-level graph construction helpers (from execution_graph)
    graph_node_for_statement/3,   % graph_node_for_statement(+Type, +Data, -NodeId)
    graph_node_for_branch/3,      % graph_node_for_branch(+Cond, +Value, -NodeId)
    graph_node_for_assignment/4,  % graph_node_for_assignment(+Var, +Val, +Expr, -NodeId)

    % Convenience trace recording predicates (from trace_events)
    trace_statement_start/2,
    trace_statement_end/2,
    trace_branch/4,
    trace_var_assign/3,
    trace_var_read/2,
    trace_proc_enter/2,
    trace_proc_exit/2,
    trace_method_enter/3,
    trace_method_exit/3,
    trace_loop_start/2,
    trace_loop_iteration/3,
    trace_loop_end/2,
    trace_case_match/3,
    trace_file_op/4,
    trace_error/1,

    % ML-friendly exports (from ml_export)
    graph_to_adjacency/3,     % graph_to_adjacency(+Graph, -AdjList, -NodeTypes)
    graph_to_edge_index/3,    % graph_to_edge_index(+Graph, -EdgeIndex, -EdgeTypes) - PyTorch Geometric format
    graph_to_numpy_json/2,    % graph_to_numpy_json(+Graph, -JsonString) - NumPy/PyTorch friendly
    node_type_encoding/3,     % node_type_encoding(+Nodes, -TypeIds, -TypeMapping)

    % Probabilistic graphical model (from probabilistic_model)
    graph_to_pgm/2,           % graph_to_pgm(+Graph, -PGM) - Convert to Bayesian network structure
    path_probability/3,       % path_probability(+Graph, +Path, -Prob)
    sample_path/4,            % sample_path(+Graph, +InputDist, -Path, -Prob)

    % Probabilistic programming exports (from probabilistic_model)
    pgm_to_pymc/2,            % pgm_to_pymc(+PGM, -PythonCode) - Generate PyMC model
    pgm_to_stan/2,            % pgm_to_stan(+PGM, -StanCode) - Generate Stan model
    pgm_to_python_package/3,  % pgm_to_python_package(+PGM, +Graph, -Files) - Complete package

    % GNN-VAE exports for latent space learning (from gnn_vae)
    graph_to_gnn_dataset/2,   % graph_to_gnn_dataset(+Graphs, -DatasetJson)
    generate_gnn_vae_code/1,  % generate_gnn_vae_code(-PythonCode)
    generate_gnn_vae_package/2 % generate_gnn_vae_package(+Graphs, -Files)
]).

%------------------------------------------------------------
% Load submodules (import nothing to avoid override warnings)
%------------------------------------------------------------

:- use_module(tracer/trace_core, []).
:- use_module(tracer/trace_events, []).
:- use_module(tracer/trace_retrieval, []).
:- use_module(tracer/execution_graph, []).
:- use_module(tracer/graph_export, []).
:- use_module(tracer/ml_export, []).
:- use_module(tracer/probabilistic_model, []).
:- use_module(tracer/gnn_vae, []).

%------------------------------------------------------------
% Re-export predicates from submodules
%------------------------------------------------------------

% Trace control (trace_core) - start_trace defined below with graph init
stop_trace(Trace) :- trace_core:stop_trace(Trace).
is_tracing :- trace_core:is_tracing.
clear_trace :- trace_core:clear_trace, execution_graph:clear_graph.

% Event recording (trace_core)
trace_event(Event) :- trace_core:trace_event(Event).
trace_event(Type, Data) :- trace_core:trace_event(Type, Data).

% Trace retrieval (trace_retrieval)
get_trace(Trace) :- trace_retrieval:get_trace(Trace).
get_execution_path(Path) :- trace_retrieval:get_execution_path(Path).
get_branch_decisions(Decisions) :- trace_retrieval:get_branch_decisions(Decisions).
get_variable_history(Var, History) :- trace_retrieval:get_variable_history(Var, History).
get_call_stack(Stack) :- trace_events:get_call_stack(Stack).

% Trace analysis (trace_retrieval)
trace_summary(Summary) :- trace_retrieval:trace_summary(Summary).
path_to_dot(Trace, Dot) :- graph_export:path_to_dot(Trace, Dot).

% Execution graph (execution_graph)
get_execution_graph(Graph) :- execution_graph:get_execution_graph(Graph).
get_data_flow(Flow) :- execution_graph:get_data_flow(Flow).
get_control_flow(Flow) :- execution_graph:get_control_flow(Flow).

% Graph export (graph_export)
graph_to_dot(Graph, Dot) :- graph_export:graph_to_dot(Graph, Dot).
graph_to_json(Graph, Json) :- graph_export:graph_to_json(Graph, Json).

% Graph node operations (execution_graph)
add_graph_node(Type, Data, Id) :- execution_graph:add_graph_node(Type, Data, Id).
add_graph_edge(From, To, Type) :- execution_graph:add_graph_edge(From, To, Type).
current_node_id(Id) :- execution_graph:current_node_id(Id).
set_current_node(Id) :- execution_graph:set_current_node(Id).

% Data dependency tracking (execution_graph)
record_var_write(Var, NodeId) :- execution_graph:record_var_write(Var, NodeId).
record_var_read(Var, NodeId) :- execution_graph:record_var_read(Var, NodeId).

% High-level graph helpers (execution_graph)
graph_node_for_statement(Type, Data, Id) :- execution_graph:graph_node_for_statement(Type, Data, Id).
graph_node_for_branch(Cond, Val, Id) :- execution_graph:graph_node_for_branch(Cond, Val, Id).
graph_node_for_assignment(Var, Val, Expr, Id) :- execution_graph:graph_node_for_assignment(Var, Val, Expr, Id).

% Convenience trace recording (trace_events)
trace_statement_start(Type, AST) :- trace_events:trace_statement_start(Type, AST).
trace_statement_end(Type, Control) :- trace_events:trace_statement_end(Type, Control).
trace_branch(Ctx, Cond, Val, Taken) :- trace_events:trace_branch(Ctx, Cond, Val, Taken).
trace_var_assign(Var, Old, New) :- trace_events:trace_var_assign(Var, Old, New).
trace_var_read(Var, Val) :- trace_events:trace_var_read(Var, Val).
trace_proc_enter(Name, Args) :- trace_events:trace_proc_enter(Name, Args).
trace_proc_exit(Name, Result) :- trace_events:trace_proc_exit(Name, Result).
trace_method_enter(Obj, Method, Args) :- trace_events:trace_method_enter(Obj, Method, Args).
trace_method_exit(Obj, Method, Result) :- trace_events:trace_method_exit(Obj, Method, Result).
trace_loop_start(Type, Info) :- trace_events:trace_loop_start(Type, Info).
trace_loop_iteration(Type, Iter, Cond) :- trace_events:trace_loop_iteration(Type, Iter, Cond).
trace_loop_end(Type, Reason) :- trace_events:trace_loop_end(Type, Reason).
trace_case_match(Val, Matched, Idx) :- trace_events:trace_case_match(Val, Matched, Idx).
trace_file_op(Op, File, Key, Result) :- trace_events:trace_file_op(Op, File, Key, Result).
trace_error(Msg) :- trace_events:trace_error(Msg).

% ML exports (ml_export)
graph_to_adjacency(Graph, Adj, Types) :- ml_export:graph_to_adjacency(Graph, Adj, Types).
graph_to_edge_index(Graph, Idx, Types) :- ml_export:graph_to_edge_index(Graph, Idx, Types).
graph_to_numpy_json(Graph, Json) :- ml_export:graph_to_numpy_json(Graph, Json).
node_type_encoding(Nodes, Ids, Map) :- ml_export:node_type_encoding(Nodes, Ids, Map).

% Probabilistic model (probabilistic_model)
graph_to_pgm(Graph, PGM) :- probabilistic_model:graph_to_pgm(Graph, PGM).
path_probability(Graph, Path, Prob) :- probabilistic_model:path_probability(Graph, Path, Prob).
sample_path(Graph, Dist, Path, Prob) :- probabilistic_model:sample_path(Graph, Dist, Path, Prob).
pgm_to_pymc(PGM, Code) :- probabilistic_model:pgm_to_pymc(PGM, Code).
pgm_to_stan(PGM, Code) :- probabilistic_model:pgm_to_stan(PGM, Code).
pgm_to_python_package(PGM, Graph, Files) :- probabilistic_model:pgm_to_python_package(PGM, Graph, Files).

% GNN-VAE (gnn_vae)
graph_to_gnn_dataset(Graphs, Json) :- gnn_vae:graph_to_gnn_dataset(Graphs, Json).
generate_gnn_vae_code(Code) :- gnn_vae:generate_gnn_vae_code(Code).
generate_gnn_vae_package(Graphs, Files) :- gnn_vae:generate_gnn_vae_package(Graphs, Files).

%------------------------------------------------------------
% start_trace with graph initialization
%------------------------------------------------------------

start_trace :-
    trace_core:start_trace,
    execution_graph:init_graph.

start_trace(Options) :-
    trace_core:start_trace(Options),
    execution_graph:init_graph.

%------------------------------------------------------------
% Tests
%------------------------------------------------------------

:- use_module(library(plunit)).

:- begin_tests(execution_tracer).

test(trace_control) :-
    clear_trace,
    \+ is_tracing,
    start_trace,
    is_tracing,
    trace_event(test, data{value: 1}),
    stop_trace(Trace),
    \+ is_tracing,
    Trace.summary.total_events > 0.

test(trace_events) :-
    start_trace,
    trace_event(statement_start, stmt{type: assign, ast: test}),
    trace_event(var_assign, var{name: 'X', old: 0, new: 42}),
    trace_event(branch_decision, branch{context: if, condition: 'X > 0', value: true, branch_taken: true}),
    stop_trace(Trace),
    length(Trace.events, 3).

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

% Graph tests
test(graph_creation) :-
    start_trace,
    % Should have root node
    get_execution_graph(Graph),
    Graph.metadata.node_count > 0,
    stop_trace(_).

test(graph_nodes_and_edges) :-
    start_trace,
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

test(graph_to_dot_export) :-
    start_trace,
    add_graph_node(assign, assign{var: 'X', value: 10}, _),
    get_execution_graph(Graph),
    graph_to_dot(Graph, DotString),
    sub_string(DotString, _, _, _, "digraph"),
    stop_trace(_).

:- end_tests(execution_tracer).
