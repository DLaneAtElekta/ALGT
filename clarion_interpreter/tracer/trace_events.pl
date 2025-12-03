%============================================================
% trace_events.pl - Convenience Recording Predicates
%
% High-level predicates for recording specific types of
% trace events during execution.
%============================================================

:- module(trace_events, [
    % Statement tracing
    trace_statement_start/2,
    trace_statement_end/2,

    % Branch tracing
    trace_branch/4,

    % Variable tracing
    trace_var_assign/3,
    trace_var_read/2,

    % Procedure/method tracing
    trace_proc_enter/2,
    trace_proc_exit/2,
    trace_method_enter/3,
    trace_method_exit/3,

    % Loop tracing
    trace_loop_start/2,
    trace_loop_iteration/3,
    trace_loop_end/2,

    % Case tracing
    trace_case_match/3,

    % File operations
    trace_file_op/4,

    % Error tracing
    trace_error/1,

    % Call stack management
    get_call_stack/1
]).

:- use_module(trace_core).

%------------------------------------------------------------
% Call Stack State
%------------------------------------------------------------

:- dynamic trace_call_stack_store/1.

%------------------------------------------------------------
% Statement Recording
%------------------------------------------------------------

%% trace_statement_start(+StmtType, +StmtAST) is det.
%
% Record the start of a statement execution.

trace_statement_start(StmtType, StmtAST) :-
    trace_event(statement_start, stmt{type: StmtType, ast: StmtAST}).

%% trace_statement_end(+StmtType, +Control) is det.
%
% Record the end of a statement execution.
% Control indicates how the statement completed (normal, break, cycle, etc.)

trace_statement_end(StmtType, Control) :-
    trace_event(statement_end, stmt{type: StmtType, control: Control}).

%------------------------------------------------------------
% Branch Recording
%------------------------------------------------------------

%% trace_branch(+Context, +Condition, +Value, +BranchTaken) is det.
%
% Record a branch decision.
% Context: if, case, loop, etc.
% Condition: The condition expression
% Value: The evaluated value of the condition
% BranchTaken: true/false or the matched case value

trace_branch(Context, Condition, Value, BranchTaken) :-
    trace_event(branch_decision, branch{
        context: Context,
        condition: Condition,
        value: Value,
        branch_taken: BranchTaken
    }).

%------------------------------------------------------------
% Variable Recording
%------------------------------------------------------------

%% trace_var_assign(+VarName, +OldValue, +NewValue) is det.
%
% Record a variable assignment.

trace_var_assign(VarName, OldValue, NewValue) :-
    trace_event(var_assign, var{name: VarName, old: OldValue, new: NewValue}).

%% trace_var_read(+VarName, +Value) is det.
%
% Record a variable read.

trace_var_read(VarName, Value) :-
    trace_event(var_read, var{name: VarName, value: Value}).

%------------------------------------------------------------
% Procedure/Method Recording
%------------------------------------------------------------

%% trace_proc_enter(+Name, +Args) is det.
%
% Record entering a procedure.

trace_proc_enter(Name, Args) :-
    trace_event(proc_enter, call{name: Name, args: Args}),
    push_call_stack(proc(Name)).

%% trace_proc_exit(+Name, +Result) is det.
%
% Record exiting a procedure.

trace_proc_exit(Name, Result) :-
    trace_event(proc_exit, call{name: Name, result: Result}),
    pop_call_stack.

%% trace_method_enter(+Object, +Method, +Args) is det.
%
% Record entering a method call.

trace_method_enter(Object, Method, Args) :-
    trace_event(method_enter, call{object: Object, method: Method, args: Args}),
    push_call_stack(method(Object, Method)).

%% trace_method_exit(+Object, +Method, +Result) is det.
%
% Record exiting a method call.

trace_method_exit(Object, Method, Result) :-
    trace_event(method_exit, call{object: Object, method: Method, result: Result}),
    pop_call_stack.

%------------------------------------------------------------
% Loop Recording
%------------------------------------------------------------

%% trace_loop_start(+LoopType, +Info) is det.
%
% Record the start of a loop.

trace_loop_start(LoopType, Info) :-
    trace_event(loop_start, loop{type: LoopType, info: Info}).

%% trace_loop_iteration(+LoopType, +Iteration, +CondValue) is det.
%
% Record a loop iteration.

trace_loop_iteration(LoopType, Iteration, CondValue) :-
    trace_event(loop_iteration, loop{type: LoopType, iteration: Iteration, cond_value: CondValue}).

%% trace_loop_end(+LoopType, +Reason) is det.
%
% Record the end of a loop.
% Reason: normal, break, condition_false, etc.

trace_loop_end(LoopType, Reason) :-
    trace_event(loop_end, loop{type: LoopType, reason: Reason}).

%------------------------------------------------------------
% Case Recording
%------------------------------------------------------------

%% trace_case_match(+Value, +MatchedCase, +Index) is det.
%
% Record a CASE statement match.

trace_case_match(Value, MatchedCase, Index) :-
    trace_event(case_match, case{value: Value, matched: MatchedCase, index: Index}).

%------------------------------------------------------------
% File Operation Recording
%------------------------------------------------------------

%% trace_file_op(+Operation, +FileName, +Key, +Result) is det.
%
% Record a file/database operation.

trace_file_op(Operation, FileName, Key, Result) :-
    trace_event(file_op, file{op: Operation, name: FileName, key: Key, result: Result}).

%------------------------------------------------------------
% Error Recording
%------------------------------------------------------------

%% trace_error(+Message) is det.
%
% Record an error event.

trace_error(Message) :-
    trace_event(error, error{message: Message}).

%------------------------------------------------------------
% Call Stack Management
%------------------------------------------------------------

push_call_stack(Entry) :-
    ( retract(trace_call_stack_store(Stack))
    -> true
    ;  Stack = []
    ),
    assertz(trace_call_stack_store([Entry|Stack])).

pop_call_stack :-
    ( retract(trace_call_stack_store([_|Rest]))
    -> assertz(trace_call_stack_store(Rest))
    ;  true
    ).

%% get_call_stack(-Stack) is det.
%
% Get the current call stack.

get_call_stack(Stack) :-
    ( trace_call_stack_store(Stack)
    -> true
    ;  Stack = []
    ).

%------------------------------------------------------------
% Cleanup on trace clear
%------------------------------------------------------------
% Note: The call stack is cleared when trace_core:clear_trace is called.
% This module should register a cleanup hook if needed.

:- initialization((
    % Clear call stack when module loads
    retractall(trace_call_stack_store(_)),
    assertz(trace_call_stack_store([]))
)).
