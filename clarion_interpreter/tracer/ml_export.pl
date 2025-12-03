%============================================================
% ml_export.pl - ML-Friendly Export Formats
%
% Export execution graphs in formats suitable for machine
% learning libraries:
%   - Adjacency list format
%   - PyTorch Geometric COO format (edge_index)
%   - NumPy/PyTorch-friendly JSON
%   - Node type encodings
%============================================================

:- module(ml_export, [
    % ML-friendly exports
    graph_to_adjacency/3,     % graph_to_adjacency(+Graph, -AdjList, -NodeTypes)
    graph_to_edge_index/3,    % graph_to_edge_index(+Graph, -EdgeIndex, -EdgeTypes) - PyTorch Geometric format
    graph_to_numpy_json/2,    % graph_to_numpy_json(+Graph, -JsonString) - NumPy/PyTorch friendly
    node_type_encoding/3      % node_type_encoding(+Nodes, -TypeIds, -TypeMapping)
]).

%------------------------------------------------------------
% Adjacency List Format
%------------------------------------------------------------

%% graph_to_adjacency(+Graph, -AdjList, -NodeTypes) is det.
%
% Export graph as adjacency list format suitable for graph ML libraries.
% AdjList: List of [From, To] pairs (0-indexed for Python/C++)
% NodeTypes: List of node type atoms in order

graph_to_adjacency(Graph, AdjList, NodeTypes) :-
    Graph = graph{nodes: Nodes, edges: Edges, metadata: _},
    % Extract node types in ID order
    msort(Nodes, SortedNodes),
    maplist(node_type, SortedNodes, NodeTypes),
    % Convert edges to 0-indexed pairs
    findall([From1, To1],
        (member(edge(From, To, _), Edges),
         From1 is From - 1,  % Convert to 0-indexed
         To1 is To - 1),
        AdjList).

node_type(node(_, Type, _), Type).

%------------------------------------------------------------
% PyTorch Geometric COO Format
%------------------------------------------------------------

%% graph_to_edge_index(+Graph, -EdgeIndex, -EdgeTypes) is det.
%
% Export in PyTorch Geometric COO format (edge_index tensor).
% EdgeIndex: [[src1,src2,...], [dst1,dst2,...]] (0-indexed)
% EdgeTypes: List of edge type atoms

graph_to_edge_index(Graph, EdgeIndex, EdgeTypes) :-
    Graph = graph{nodes: _, edges: Edges, metadata: _},
    findall(From1-To1-Type,
        (member(edge(From, To, Type), Edges),
         From1 is From - 1,
         To1 is To - 1),
        EdgeData),
    maplist(edge_src, EdgeData, Srcs),
    maplist(edge_dst, EdgeData, Dsts),
    maplist(edge_type_only, EdgeData, EdgeTypes),
    EdgeIndex = [Srcs, Dsts].

edge_src(S-_-_, S).
edge_dst(_-D-_, D).
edge_type_only(_-_-T, T).

%------------------------------------------------------------
% NumPy/PyTorch-friendly JSON
%------------------------------------------------------------

%% graph_to_numpy_json(+Graph, -JsonString) is det.
%
% Export graph in JSON format optimized for numpy/PyTorch loading.
% Includes adjacency as COO sparse matrix format.

graph_to_numpy_json(Graph, JsonString) :-
    Graph = graph{nodes: Nodes, edges: Edges, metadata: Meta},
    length(Nodes, NumNodes),
    length(Edges, NumEdges),
    % Build edge index arrays
    graph_to_edge_index(Graph, [Srcs, Dsts], EdgeTypes),
    % Build node feature vectors (one-hot encoded types)
    node_type_encoding(Nodes, NodeTypeIds, TypeMapping),
    % Build branch info for probabilistic modeling
    findall(branch_info{node: N1, condition: C, value: V},
        (member(node(N, branch, node_data{data: D, timestamp: _}), Nodes),
         N1 is N - 1,
         C = D.condition,
         V = D.value),
        BranchInfos),
    format(string(JsonString),
'{
  "num_nodes": ~d,
  "num_edges": ~d,
  "edge_index": [~w, ~w],
  "edge_types": ~w,
  "node_type_ids": ~w,
  "type_mapping": ~w,
  "branch_nodes": ~w,
  "metadata": ~w
}',
        [NumNodes, NumEdges, Srcs, Dsts, EdgeTypes, NodeTypeIds, TypeMapping, BranchInfos, Meta]).

%------------------------------------------------------------
% Node Type Encoding
%------------------------------------------------------------

%% node_type_encoding(+Nodes, -TypeIds, -TypeMapping) is det.
%
% Encode node types as integers for neural network input.
% TypeIds: List of integer type IDs for each node (in node order)
% TypeMapping: List of Type-Id pairs for decoding

node_type_encoding(Nodes, TypeIds, TypeMapping) :-
    % Collect unique types
    findall(Type, member(node(_, Type, _), Nodes), Types),
    sort(Types, UniqueTypes),
    % Create mapping
    findall(Type-Id, nth0(Id, UniqueTypes, Type), TypeMapping),
    % Encode each node
    msort(Nodes, SortedNodes),
    maplist(encode_node_type(TypeMapping), SortedNodes, TypeIds).

encode_node_type(Mapping, node(_, Type, _), Id) :-
    member(Type-Id, Mapping), !.
encode_node_type(_, _, -1).
