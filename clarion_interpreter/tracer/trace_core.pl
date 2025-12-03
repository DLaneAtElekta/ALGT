%============================================================
% trace_core.pl - Core Trace State and Control
%
% Manages global trace state and provides the fundamental
% tracing operations: start, stop, event recording.
%============================================================

:- module(trace_core, [
    % Trace control
    start_trace/0,
    start_trace/1,          % start_trace(+Options)
    stop_trace/1,           % stop_trace(-Trace)
    is_tracing/0,
    clear_trace/0,

    % Event recording
    trace_event/1,          % trace_event(+Event)
    trace_event/2,          % trace_event(+EventType, +Data)

    % Internal predicates (exported for other tracer modules)
    next_event_id/1,
    should_capture/2,
    get_trace_options/1
]).

%------------------------------------------------------------
% Global State (using dynamic predicates for trace storage)
%------------------------------------------------------------
%
% Trace state stored in dynamic predicates:
%   trace_enabled    - true/false
%   trace_events     - list of trace events (newest first)
%   trace_options    - configuration options
%   trace_start_time - when tracing started

:- dynamic trace_enabled/1.
:- dynamic trace_event_store/1.
:- dynamic trace_options_store/1.
:- dynamic trace_start_time/1.
:- dynamic trace_event_counter/1.

%------------------------------------------------------------
% Trace Event Structure
%------------------------------------------------------------
% Events are represented as:
%   event(Id, Timestamp, Type, Data)
%
% Event types:
%   statement_start(StmtType, StmtAST)
%   statement_end(StmtType, Control)
%   branch_decision(Context, Condition, Value, BranchTaken)
%   var_assign(VarName, OldValue, NewValue)
%   var_read(VarName, Value)
%   proc_enter(Name, Args)
%   proc_exit(Name, Result)
%   method_enter(Object, Method, Args)
%   method_exit(Object, Method, Result)
%   loop_iteration(LoopType, Iteration, CondValue)
%   file_op(Operation, FileName, Key, Result)
%   error(Message)

%------------------------------------------------------------
% Trace Control
%------------------------------------------------------------

%% start_trace is det.
%% start_trace(+Options) is det.
%
% Start capturing execution trace.
% Options is a dict with optional keys:
%   - capture_vars: true/false (default: true) - capture variable assignments
%   - capture_reads: true/false (default: false) - capture variable reads
%   - capture_statements: true/false (default: true) - capture statement execution
%   - capture_branches: true/false (default: true) - capture branch decisions
%   - capture_calls: true/false (default: true) - capture procedure calls
%   - capture_file_ops: true/false (default: true) - capture file operations
%   - max_events: integer (default: 100000) - maximum events to capture

start_trace :-
    start_trace(trace_options{
        capture_vars: true,
        capture_reads: false,
        capture_statements: true,
        capture_branches: true,
        capture_calls: true,
        capture_file_ops: true,
        max_events: 100000
    }).

start_trace(Options) :-
    clear_trace_state,
    get_time(StartTime),
    assertz(trace_enabled(true)),
    assertz(trace_options_store(Options)),
    assertz(trace_start_time(StartTime)),
    assertz(trace_event_counter(0)).

%% stop_trace(-Trace) is det.
%
% Stop tracing and return the collected trace.
% Trace is a dict containing:
%   - events: list of events in chronological order
%   - duration: elapsed time in seconds
%   - summary: quick statistics

stop_trace(Trace) :-
    ( trace_start_time(StartTime)
    -> get_time(EndTime),
       Duration is EndTime - StartTime
    ;  Duration = 0
    ),
    get_all_events(Events),
    compute_summary(Events, Summary),
    Trace = trace{
        events: Events,
        duration: Duration,
        summary: Summary
    },
    clear_trace_state.

%% is_tracing is semidet.
%
% Succeeds if tracing is currently enabled.

is_tracing :-
    trace_enabled(true).

%% clear_trace is det.
%
% Clear all trace state (public API).

clear_trace :-
    clear_trace_state.

%% clear_trace_state is det.
%
% Internal: Clear all trace-related dynamic predicates.

clear_trace_state :-
    retractall(trace_enabled(_)),
    retractall(trace_event_store(_)),
    retractall(trace_options_store(_)),
    retractall(trace_start_time(_)),
    retractall(trace_event_counter(_)).

%------------------------------------------------------------
% Event Recording
%------------------------------------------------------------

%% trace_event(+Event) is det.
%
% Record a trace event if tracing is enabled.

trace_event(Event) :-
    ( is_tracing
    -> record_event(Event)
    ;  true
    ).

%% trace_event(+EventType, +Data) is det.
%
% Record a typed trace event.

trace_event(EventType, Data) :-
    trace_event(event_data(EventType, Data)).

%% record_event(+Event) is det.
%
% Internal: actually record the event with timestamp and ID.

record_event(Event) :-
    trace_options_store(Options),
    should_capture(Event, Options),
    !,
    get_time(Timestamp),
    next_event_id(Id),
    ( Options.max_events > 0,
      Id > Options.max_events
    -> true  % Skip if over limit
    ;  FullEvent = event(Id, Timestamp, Event),
       assertz(trace_event_store(FullEvent))
    ).
record_event(_).  % Silently ignore if not capturing this event type

%% next_event_id(-Id) is det.
%
% Get the next event ID.

next_event_id(Id) :-
    retract(trace_event_counter(Current)),
    Id is Current + 1,
    assertz(trace_event_counter(Id)).

%% should_capture(+Event, +Options) is semidet.
%
% Check if this event type should be captured based on options.

should_capture(event_data(statement_start, _), Opts) :- Opts.capture_statements.
should_capture(event_data(statement_end, _), Opts) :- Opts.capture_statements.
should_capture(event_data(branch_decision, _), Opts) :- Opts.capture_branches.
should_capture(event_data(var_assign, _), Opts) :- Opts.capture_vars.
should_capture(event_data(var_read, _), Opts) :- Opts.capture_reads.
should_capture(event_data(proc_enter, _), Opts) :- Opts.capture_calls.
should_capture(event_data(proc_exit, _), Opts) :- Opts.capture_calls.
should_capture(event_data(method_enter, _), Opts) :- Opts.capture_calls.
should_capture(event_data(method_exit, _), Opts) :- Opts.capture_calls.
should_capture(event_data(loop_iteration, _), Opts) :- Opts.capture_branches.
should_capture(event_data(loop_start, _), Opts) :- Opts.capture_branches.
should_capture(event_data(loop_end, _), Opts) :- Opts.capture_branches.
should_capture(event_data(file_op, _), Opts) :- Opts.capture_file_ops.
should_capture(event_data(case_match, _), Opts) :- Opts.capture_branches.
should_capture(event_data(error, _), _) :- true.  % Always capture errors
should_capture(_, _) :- true.  % Default: capture unknown events

%------------------------------------------------------------
% Internal Helpers
%------------------------------------------------------------

%% get_trace_options(-Options) is det.
%
% Get current trace options (for use by other modules).

get_trace_options(Options) :-
    ( trace_options_store(Options)
    -> true
    ;  Options = trace_options{}
    ).

%% get_all_events(-Events) is det.
%
% Get all trace events in chronological order.

get_all_events(Events) :-
    findall(E, trace_event_store(E), EventsReversed),
    reverse(EventsReversed, Events).

%% compute_summary(+Events, -Summary) is det.
%
% Compute a summary of the trace events.

compute_summary(Events, Summary) :-
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

is_branch_event(event(_, _, event_data(branch_decision, _))).

is_true_branch(event(_, _, event_data(branch_decision, Data))) :-
    Data.branch_taken = true.
