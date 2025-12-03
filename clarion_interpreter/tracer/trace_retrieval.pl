%============================================================
% trace_retrieval.pl - Trace Retrieval and Analysis
%
% Provides predicates for querying and analyzing collected
% trace data: execution paths, branch decisions, variable
% history, and summary statistics.
%============================================================

:- module(trace_retrieval, [
    % Trace retrieval
    get_trace/1,            % get_trace(-Trace)
    get_execution_path/1,   % get_execution_path(-Path)
    get_branch_decisions/1, % get_branch_decisions(-Decisions)
    get_variable_history/2, % get_variable_history(+VarName, -History)

    % Trace analysis
    trace_summary/1,        % trace_summary(-Summary)

    % Path extraction (used by graph_export)
    extract_path/2
]).

:- use_module(trace_core).

%------------------------------------------------------------
% Trace Retrieval
%------------------------------------------------------------

%% get_trace(-Events) is det.
%
% Get all trace events in chronological order.

get_trace(Events) :-
    findall(E, trace_core:trace_event_store(E), Events).

%% get_execution_path(-Path) is det.
%
% Get the execution path as a sequence of statement types and branch decisions.
% Path elements:
%   - stmt(Type) - a statement of the given type
%   - branch(Context, Taken) - a branch decision
%   - enter(Name) - procedure entry
%   - exit(Name) - procedure exit

get_execution_path(Path) :-
    get_trace(Events),
    extract_path(Events, Path).

%% extract_path(+Events, -Path) is det.
%
% Extract execution path from event list.

extract_path([], []).
extract_path([event(_, _, event_data(statement_start, Data))|Rest], [stmt(Type)|Path]) :-
    Type = Data.type,
    extract_path(Rest, Path).
extract_path([event(_, _, event_data(branch_decision, Data))|Rest], [branch(Context, Taken)|Path]) :-
    Context = Data.context,
    Taken = Data.branch_taken,
    extract_path(Rest, Path).
extract_path([event(_, _, event_data(proc_enter, Data))|Rest], [enter(Name)|Path]) :-
    Name = Data.name,
    extract_path(Rest, Path).
extract_path([event(_, _, event_data(proc_exit, Data))|Rest], [exit(Name)|Path]) :-
    Name = Data.name,
    extract_path(Rest, Path).
extract_path([_|Rest], Path) :-
    extract_path(Rest, Path).

%% get_branch_decisions(-Decisions) is det.
%
% Get all branch decisions as a list.
% Each decision is a dict with:
%   - id: event ID
%   - time: timestamp
%   - context: if/case/loop
%   - condition: the condition expression
%   - value: evaluated value
%   - branch: which branch was taken

get_branch_decisions(Decisions) :-
    get_trace(Events),
    include(is_branch_event, Events, BranchEvents),
    maplist(extract_branch_data, BranchEvents, Decisions).

is_branch_event(event(_, _, event_data(branch_decision, _))).

extract_branch_data(event(Id, Time, event_data(branch_decision, Data)),
    decision{id: Id, time: Time, context: Data.context,
             condition: Data.condition, value: Data.value,
             branch: Data.branch_taken}).

%% get_variable_history(+VarName, -History) is det.
%
% Get the history of assignments to a variable.
% History is a list of dicts with:
%   - id: event ID
%   - time: timestamp
%   - old: previous value
%   - new: new value

get_variable_history(VarName, History) :-
    get_trace(Events),
    include(is_var_event(VarName), Events, VarEvents),
    maplist(extract_var_data, VarEvents, History).

is_var_event(VarName, event(_, _, event_data(var_assign, Data))) :-
    Data.name = VarName.

extract_var_data(event(Id, Time, event_data(var_assign, Data)),
    assign{id: Id, time: Time, old: Data.old, new: Data.new}).

%------------------------------------------------------------
% Trace Analysis
%------------------------------------------------------------

%% trace_summary(-Summary) is det.
%
% Get a summary of the trace.
% Summary is a dict with:
%   - total_events: number of events
%   - event_types: list of type-count pairs
%   - branch_stats: dict with total, true_branches, false_branches

trace_summary(Summary) :-
    get_trace(Events),
    length(Events, TotalEvents),
    count_event_types(Events, TypeCounts),
    count_branches(Events, BranchCounts),
    Summary = summary{
        total_events: TotalEvents,
        event_types: TypeCounts,
        branch_stats: BranchCounts
    }.

count_event_types(Events, Counts) :-
    findall(Type, (member(event(_, _, event_data(Type, _)), Events)), Types),
    msort(Types, SortedTypes),
    clumped(SortedTypes, Counts).

count_branches(Events, branch_stats{total: Total, true_branches: True, false_branches: False}) :-
    include(is_branch_event, Events, BranchEvents),
    length(BranchEvents, Total),
    include(is_true_branch, BranchEvents, TrueEvents),
    length(TrueEvents, True),
    False is Total - True.

is_true_branch(event(_, _, event_data(branch_decision, Data))) :-
    Data.branch_taken = true.
