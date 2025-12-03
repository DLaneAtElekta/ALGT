%============================================================
% graph_export.pl - DOT and JSON Export
%
% Export execution graphs to various visualization formats:
%   - GraphViz DOT format
%   - JSON format for web visualization
%   - Path visualization
%============================================================

:- module(graph_export, [
    % DOT format export
    graph_to_dot/2,         % graph_to_dot(+Graph, -DotString)
    path_to_dot/2,          % path_to_dot(+Trace, -DotString)

    % JSON format export
    graph_to_json/2         % graph_to_json(+Graph, -JsonString)
]).

:- use_module(trace_retrieval).

%------------------------------------------------------------
% Graph Export (DOT format)
%------------------------------------------------------------

%% graph_to_dot(+Graph, -DotString) is det.
%
% Convert execution graph to GraphViz DOT format.
% Shows both control flow (solid arrows) and data flow (dashed arrows).

graph_to_dot(Graph, DotString) :-
    Graph = graph{nodes: Nodes, edges: Edges, metadata: _},
    nodes_to_dot(Nodes, NodeStrings),
    edges_to_dot(Edges, EdgeStrings),
    atomics_to_string([
        "digraph execution_graph {\n",
        "  rankdir=TB;\n",
        "  node [shape=box fontname=\"Courier\"];\n",
        "  \n",
        "  // Nodes\n",
        NodeStrings,
        "  \n",
        "  // Edges\n",
        EdgeStrings,
        "}\n"
    ], DotString).

nodes_to_dot([], "").
nodes_to_dot([Node|Rest], Result) :-
    node_to_dot(Node, NodeStr),
    nodes_to_dot(Rest, RestStr),
    atomics_to_string([NodeStr, RestStr], Result).

node_to_dot(node(Id, Type, Data), Str) :-
    node_label(Type, Data, Label),
    node_style(Type, Style),
    format(string(Str), "  n~d [label=\"~w\" ~w];~n", [Id, Label, Style]).

node_label(root, _, "START").
node_label(assign, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "~w = ...", [D.var]).
node_label(branch, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "~w?\\n(~w)", [D.condition, D.value]).
node_label(call, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "CALL ~w", [D.name]).
node_label(return, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "RETURN ~w", [D.value]).
node_label(loop, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "LOOP ~w", [D.type]).
node_label(file_op, node_data{data: D, timestamp: _}, Label) :-
    format(string(Label), "~w(~w)", [D.op, D.file]).
node_label(Type, _, Label) :-
    format(string(Label), "~w", [Type]).

node_style(root, "shape=ellipse style=filled fillcolor=lightgray").
node_style(assign, "shape=box").
node_style(branch, "shape=diamond style=filled fillcolor=lightyellow").
node_style(call, "shape=box style=filled fillcolor=lightblue").
node_style(return, "shape=box style=filled fillcolor=lightgreen").
node_style(loop, "shape=hexagon style=filled fillcolor=lightcoral").
node_style(file_op, "shape=cylinder style=filled fillcolor=lightcyan").
node_style(_, "shape=box").

edges_to_dot([], "").
edges_to_dot([Edge|Rest], Result) :-
    edge_to_dot(Edge, EdgeStr),
    edges_to_dot(Rest, RestStr),
    atomics_to_string([EdgeStr, RestStr], Result).

edge_to_dot(edge(From, To, control), Str) :-
    format(string(Str), "  n~d -> n~d [style=solid];~n", [From, To]).
edge_to_dot(edge(From, To, data(Var)), Str) :-
    format(string(Str), "  n~d -> n~d [style=dashed color=blue label=\"~w\"];~n", [From, To, Var]).
edge_to_dot(edge(From, To, branch(Direction)), Str) :-
    format(string(Str), "  n~d -> n~d [style=bold label=\"~w\"];~n", [From, To, Direction]).
edge_to_dot(edge(From, To, _), Str) :-
    format(string(Str), "  n~d -> n~d;~n", [From, To]).

%------------------------------------------------------------
% Graph Export (JSON format)
%------------------------------------------------------------

%% graph_to_json(+Graph, -JsonString) is det.
%
% Convert execution graph to JSON format for visualization tools.

graph_to_json(Graph, JsonString) :-
    Graph = graph{nodes: Nodes, edges: Edges, metadata: Meta},
    nodes_to_json(Nodes, NodesJson),
    edges_to_json(Edges, EdgesJson),
    format(string(JsonString),
        "{~n  \"metadata\": ~w,~n  \"nodes\": [~n~w  ],~n  \"edges\": [~n~w  ]~n}~n",
        [Meta, NodesJson, EdgesJson]).

nodes_to_json([], "").
nodes_to_json([Node], Str) :- !,
    node_to_json(Node, Str).
nodes_to_json([Node|Rest], Result) :-
    node_to_json(Node, NodeStr),
    nodes_to_json(Rest, RestStr),
    atomics_to_string([NodeStr, ",\n", RestStr], Result).

node_to_json(node(Id, Type, Data), Str) :-
    format(string(Str), "    {\"id\": ~d, \"type\": \"~w\", \"data\": ~w}", [Id, Type, Data]).

edges_to_json([], "").
edges_to_json([Edge], Str) :- !,
    edge_to_json(Edge, Str).
edges_to_json([Edge|Rest], Result) :-
    edge_to_json(Edge, EdgeStr),
    edges_to_json(Rest, RestStr),
    atomics_to_string([EdgeStr, ",\n", RestStr], Result).

edge_to_json(edge(From, To, Type), Str) :-
    format(string(Str), "    {\"from\": ~d, \"to\": ~d, \"type\": \"~w\"}", [From, To, Type]).

%------------------------------------------------------------
% Path Visualization (DOT format)
%------------------------------------------------------------

%% path_to_dot(+Trace, -DotString) is det.
%
% Convert trace to GraphViz DOT format for visualization.

path_to_dot(trace{events: Events}, DotString) :-
    path_to_dot_events(Events, DotString).

path_to_dot_events(Events, DotString) :-
    extract_path(Events, Path),
    path_to_dot_nodes(Path, 0, NodesAndEdges),
    format(string(DotString),
        "digraph execution_path {~n  rankdir=TB;~n  node [shape=box];~n~s}~n",
        [NodesAndEdges]).

path_to_dot_nodes([], _, "").
path_to_dot_nodes([Item|Rest], N, Result) :-
    N1 is N + 1,
    item_to_dot_node(Item, N, NodeStr),
    ( Rest = []
    -> EdgeStr = ""
    ;  format(string(EdgeStr), "  n~d -> n~d;~n", [N, N1])
    ),
    path_to_dot_nodes(Rest, N1, RestStr),
    format(string(Result), "~s~s~s", [NodeStr, EdgeStr, RestStr]).

item_to_dot_node(stmt(Type), N, Str) :-
    format(string(Str), "  n~d [label=\"~w\"];~n", [N, Type]).
item_to_dot_node(branch(Context, Taken), N, Str) :-
    format(string(Str), "  n~d [label=\"~w: ~w\" shape=diamond];~n", [N, Context, Taken]).
item_to_dot_node(enter(Name), N, Str) :-
    format(string(Str), "  n~d [label=\"CALL ~w\" style=filled fillcolor=lightblue];~n", [N, Name]).
item_to_dot_node(exit(Name), N, Str) :-
    format(string(Str), "  n~d [label=\"RETURN ~w\" style=filled fillcolor=lightgreen];~n", [N, Name]).
