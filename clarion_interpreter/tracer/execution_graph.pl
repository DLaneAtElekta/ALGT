%============================================================
% execution_graph.pl - PyTorch-style DAG Construction
%
% Captures execution as a directed acyclic graph with:
%   - Nodes: Operations/statements with unique IDs
%   - Control edges: Sequential execution flow
%   - Data edges: Variable dependencies (reads from writes)
%
% Node types:
%   - root: Entry point
%   - assign: Variable assignment
%   - branch: IF/CASE decision point
%   - loop: LOOP construct
%   - call: Procedure/function call
%   - return: Return statement
%   - file_op: File operation
%
% Edge types:
%   - control: Sequential control flow
%   - data(VarName): Data dependency through variable
%============================================================

:- module(execution_graph, [
    % Graph node operations
    add_graph_node/3,       % add_graph_node(+Type, +Data, -NodeId)
    add_graph_edge/3,       % add_graph_edge(+FromId, +ToId, +EdgeType)
    current_node_id/1,      % current_node_id(-Id)
    set_current_node/1,     % set_current_node(+Id)

    % Data dependency tracking
    record_var_write/2,     % record_var_write(+VarName, +NodeId)
    record_var_read/2,      % record_var_read(+VarName, +NodeId)

    % High-level graph construction helpers
    graph_node_for_statement/3,   % graph_node_for_statement(+Type, +Data, -NodeId)
    graph_node_for_branch/3,      % graph_node_for_branch(+Cond, +Value, -NodeId)
    graph_node_for_assignment/4,  % graph_node_for_assignment(+Var, +Val, +Expr, -NodeId)

    % Graph retrieval
    get_execution_graph/1,  % get_execution_graph(-Graph)
    get_data_flow/1,        % get_data_flow(-DataFlow) - variable dependencies
    get_control_flow/1,     % get_control_flow(-ControlFlow) - statement sequence

    % Graph state management
    init_graph/0,
    clear_graph/0
]).

:- use_module(trace_core).

%------------------------------------------------------------
% Graph State
%------------------------------------------------------------

:- dynamic graph_node/3.           % graph_node(Id, Type, Data)
:- dynamic graph_edge/3.           % graph_edge(FromId, ToId, EdgeType)
:- dynamic graph_node_counter/1.   % Counter for generating node IDs
:- dynamic current_graph_node/1.   % Currently active node (for control flow edges)
:- dynamic var_last_write/2.       % var_last_write(VarName, NodeId) - tracks last write to each variable

%------------------------------------------------------------
% Graph Initialization
%------------------------------------------------------------

%% init_graph is det.
%
% Initialize the execution graph with a root node.

init_graph :-
    clear_graph,
    assertz(graph_node_counter(0)),
    add_graph_node(root, root{}, RootId),
    set_current_node(RootId).

%% clear_graph is det.
%
% Clear all graph state.

clear_graph :-
    retractall(graph_node(_, _, _)),
    retractall(graph_edge(_, _, _)),
    retractall(graph_node_counter(_)),
    retractall(current_graph_node(_)),
    retractall(var_last_write(_, _)).

%------------------------------------------------------------
% Graph Node Operations
%------------------------------------------------------------

%% add_graph_node(+Type, +Data, -NodeId) is det.
%
% Add a new node to the execution graph.
% Creates a control flow edge from the current node.
% Returns the new node's ID.

add_graph_node(Type, Data, NodeId) :-
    ( is_tracing
    -> next_graph_node_id(NodeId),
       get_time(Timestamp),
       assertz(graph_node(NodeId, Type, node_data{data: Data, timestamp: Timestamp})),
       % Add control flow edge from current node (unless this is root)
       ( Type \= root,
         current_graph_node(CurrentId)
       -> assertz(graph_edge(CurrentId, NodeId, control))
       ;  true
       )
    ;  NodeId = -1
    ).

%% add_graph_edge(+FromId, +ToId, +EdgeType) is det.
%
% Add an edge to the execution graph.
% EdgeType can be: control, data(VarName), branch(true/false)

add_graph_edge(FromId, ToId, EdgeType) :-
    ( is_tracing, FromId >= 0, ToId >= 0
    -> assertz(graph_edge(FromId, ToId, EdgeType))
    ;  true
    ).

%% current_node_id(-Id) is det.
%
% Get the current node ID (for manual edge creation).

current_node_id(Id) :-
    ( current_graph_node(Id)
    -> true
    ;  Id = -1
    ).

%% set_current_node(+Id) is det.
%
% Set the current node (used after creating branch nodes).

set_current_node(Id) :-
    ( is_tracing
    -> retractall(current_graph_node(_)),
       assertz(current_graph_node(Id))
    ;  true
    ).

%% next_graph_node_id(-Id) is det.
%
% Get the next graph node ID.

next_graph_node_id(Id) :-
    ( retract(graph_node_counter(Current))
    -> true
    ;  Current = 0
    ),
    Id is Current + 1,
    assertz(graph_node_counter(Id)).

%------------------------------------------------------------
% Data Dependency Tracking
%------------------------------------------------------------

%% record_var_write(+VarName, +NodeId) is det.
%
% Record that a variable was written at this node.

record_var_write(VarName, NodeId) :-
    ( is_tracing
    -> retractall(var_last_write(VarName, _)),
       assertz(var_last_write(VarName, NodeId))
    ;  true
    ).

%% record_var_read(+VarName, +NodeId) is det.
%
% Record that a variable was read at this node.
% Creates a data dependency edge from the last write.

record_var_read(VarName, NodeId) :-
    ( is_tracing,
      var_last_write(VarName, WriteNodeId)
    -> add_graph_edge(WriteNodeId, NodeId, data(VarName))
    ;  true
    ).

%------------------------------------------------------------
% Graph Construction Helpers
%------------------------------------------------------------

%% graph_node_for_statement(+StmtType, +StmtData, -NodeId) is det.
%
% Create a graph node for a statement and update current node.

graph_node_for_statement(StmtType, StmtData, NodeId) :-
    add_graph_node(StmtType, StmtData, NodeId),
    set_current_node(NodeId).

%% graph_node_for_branch(+Condition, +Value, -NodeId) is det.
%
% Create a branch decision node.

graph_node_for_branch(Condition, Value, NodeId) :-
    add_graph_node(branch, branch{condition: Condition, value: Value}, NodeId),
    set_current_node(NodeId).

%% graph_node_for_assignment(+VarName, +Value, +Expr, -NodeId) is det.
%
% Create an assignment node and track the variable write.

graph_node_for_assignment(VarName, Value, Expr, NodeId) :-
    add_graph_node(assign, assign{var: VarName, value: Value, expr: Expr}, NodeId),
    record_var_write(VarName, NodeId),
    set_current_node(NodeId).

%------------------------------------------------------------
% Graph Retrieval
%------------------------------------------------------------

%% get_execution_graph(-Graph) is det.
%
% Get the complete execution graph.
% Graph is a dict with nodes, edges, and metadata.

get_execution_graph(Graph) :-
    findall(node(Id, Type, Data), graph_node(Id, Type, Data), Nodes),
    findall(edge(From, To, Type), graph_edge(From, To, Type), Edges),
    % Compute some useful metadata
    length(Nodes, NodeCount),
    length(Edges, EdgeCount),
    include(is_data_edge, Edges, DataEdges),
    include(is_control_edge, Edges, ControlEdges),
    length(DataEdges, DataEdgeCount),
    length(ControlEdges, ControlEdgeCount),
    Graph = graph{
        nodes: Nodes,
        edges: Edges,
        metadata: metadata{
            node_count: NodeCount,
            edge_count: EdgeCount,
            data_edges: DataEdgeCount,
            control_edges: ControlEdgeCount
        }
    }.

is_data_edge(edge(_, _, data(_))).
is_control_edge(edge(_, _, control)).

%% get_data_flow(-DataFlow) is det.
%
% Get only the data dependency edges (variable flow).

get_data_flow(DataFlow) :-
    findall(
        flow{from: From, to: To, var: Var},
        graph_edge(From, To, data(Var)),
        DataFlow
    ).

%% get_control_flow(-ControlFlow) is det.
%
% Get only the control flow edges.

get_control_flow(ControlFlow) :-
    findall(
        flow{from: From, to: To},
        graph_edge(From, To, control),
        ControlFlow
    ).
