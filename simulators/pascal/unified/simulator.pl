% simulator.pl — Core interpreter for the Pascal/Lazarus simulator.
%
% Loads a parsed module (AST bridge output), instantiates its forms as
% runtime objects, and executes either a named method or a queued GUI event.
% Each statement is recognised; calls to TDataSet / TSQLQuery operations
% are routed through storage_backend so they appear in the SQL transaction log.

:- module(simulator, [
    load_module/2,             % load_module(+ModuleAST, -State)
    fire_event/3,              % fire_event(+Event, +S0, -S)
    invoke_method/5,           % invoke_method(+ObjectName, +MethodName, +Args, +S0, -S)
    exec_stmts/3,              % exec_stmts(+Stmts, +S0, -S)
    exec_stmt/3                % exec_stmt(+Stmt, +S0, -S)
]).

:- use_module(library(yall)).
:- use_module(simulator_state).
:- use_module(simulator_eval).
:- use_module(storage_backend).

%% ==========================================================================
%% Module loading
%% ==========================================================================

load_module(module(_UnitName, Classes, Forms, Procs, _Init), State) :-
    empty_state(S0),
    foldl(register_class_decl, Classes, S0, S1),
    foldl(register_form_decl, Forms, S1, S2),
    foldl(register_proc_decl, Procs, S2, S3),
    State = S3.

register_class_decl(class(Name, Parent, Members, Methods), S0, S) :-
    simulator_state:register_class(Name, Parent, Members, Methods, S0, S).

% Each form_decl creates both a class entry (if not already present) and an
% instance object whose name is the LFM "object Name: TClass" name. The form's
% TSQLQuery/TDataSet children become first-class objects too.
register_form_decl(form(InstanceName, ClassName, Props, Children), S0, S) :-
    simulator_state:register_form(InstanceName, ClassName, form(InstanceName, ClassName, Props, Children), S0, S1),
    simulator_state:register_object(InstanceName, ClassName, [], S1, S2),
    foldl(register_child, Children, S2, S).

register_child(form(ChildName, ChildClass, _ChildProps, _GrandChildren), S0, S) :-
    simulator_state:register_object(ChildName, ChildClass, [], S0, S).

register_proc_decl(proc(Kind, Name, Params, Ret, Locals, Body), S0, S) :-
    ( get_dict(procs, S0, Procs0) -> true ; Procs0 = _{} ),
    put_dict(Name, Procs0, proc(Kind, Params, Ret, Locals, Body), Procs),
    S = S0.put(procs, Procs).

%% ==========================================================================
%% Event delivery
%% ==========================================================================
%
% click(FormName, ControlName) → look up the LFM "OnClick" property on the
%   control, find the named method on the form's class, invoke it.

fire_event(click(FormName, ControlName), S0, S) :-
    simulator_state:lookup_form(FormName, S0, form_rt(_Class, form(_, _, _, Children))),
    member(form(ControlName, _ControlClass, Props, _), Children),
    member(prop('OnClick', ident(HandlerName)), Props), !,
    set_current_form(FormName, S0, S1),
    invoke_method(FormName, HandlerName, [ident(ControlName)], S1, S2),
    clear_current_form(S2, S).

fire_event(open(FormName), S0, S) :-
    set_current_form(FormName, S0, S1),
    ( catch(invoke_method(FormName, 'FormCreate', [ident(FormName)], S1, S2),
            _, S2 = S1)
    ),
    clear_current_form(S2, S).

fire_event(close(FormName), S0, S) :-
    set_current_form(FormName, S0, S1),
    ( catch(invoke_method(FormName, 'FormClose', [ident(FormName)], S1, S2),
            _, S2 = S1)
    ),
    clear_current_form(S2, S).

set_current_form(FormName, S0, S)   :- S = S0.put(current_form, FormName).
clear_current_form(S0, S)           :- S = S0.put(current_form, none).

%% ==========================================================================
%% Method invocation
%% ==========================================================================

invoke_method(ObjectName, MethodName, Args, S0, S) :-
    simulator_state:lookup_object(ObjectName, S0, object(ClassName, _Fields)),
    find_method(ClassName, MethodName, S0, method(_, _Kind, _, Params, _Ret, Locals, Body)),
    bind_self(ObjectName, S0, S1),
    bind_params(Params, Args, S1, S2),
    bind_locals(Locals, S2, S3),
    exec_stmts(Body, S3, S).
    % We keep the resulting state as-is. The caller's local scope is preserved
    % because invoke_method is the leaf of an event delivery; nested calls
    % rebind Self/params on entry, so leakage between scopes is harmless.

find_method(ClassName, MethodName, S, Method) :-
    simulator_state:lookup_class(ClassName, S, class_rt(_Parent, _Members, Methods)),
    member(method(ClassName, Kind, MethodName, P, R, L, B), Methods),
    Method = method(ClassName, Kind, MethodName, P, R, L, B), !.
find_method(ClassName, MethodName, S, Method) :-
    simulator_state:lookup_class(ClassName, S, class_rt(Parent, _, _)),
    Parent \== none,
    find_method(Parent, MethodName, S, Method).

bind_self(ObjectName, S0, S) :-
    set_var('Self', ident(ObjectName), S0, S).

bind_params([], [], S, S).
bind_params([param(Mode, [Name | Names], Type) | Ps], [V | Vs], S0, S) :- !,
    set_var(Name, V, S0, S1),
    ( Names = [] -> bind_params(Ps, Vs, S1, S)
    ; bind_params([param(Mode, Names, Type) | Ps], Vs, S1, S)
    ).
bind_params(_, _, S, S).

bind_locals([], S, S).
bind_locals([local(Names, _Type) | Ls], S0, S) :-
    foldl([N, A, B] >> set_var(N, unbound, A, B), Names, S0, S1),
    bind_locals(Ls, S1, S).

%% ==========================================================================
%% Statement execution
%% ==========================================================================

exec_stmts([], S, S).
exec_stmts([Stmt | Rest], S0, S) :-
    exec_stmt(Stmt, S0, S1),
    ( get_ctrl(S1, normal) -> exec_stmts(Rest, S1, S)
    ; S = S1            % short-circuit on break/continue/exit
    ).

% Compound block.
exec_stmt(compound(Stmts), S0, S) :- exec_stmts(Stmts, S0, S).

% Assignment.
exec_stmt(assign(Lhs, Rhs), S0, S) :-
    eval_expr(Rhs, S0, V),
    do_assign(Lhs, V, S0, S).

% Procedure / method invocation as a statement.
exec_stmt(call(Callee, Args), S0, S) :-
    do_call(Callee, Args, S0, S).

% Control flow.
exec_stmt(if(Cond, Then, Else), S0, S) :-
    eval_expr(Cond, S0, V),
    ( truthy(V) -> exec_stmt(Then, S0, S)
    ; ( Else == none -> S = S0 ; exec_stmt(Else, S0, S) )
    ).

exec_stmt(while(Cond, Body), S0, S) :-
    eval_expr(Cond, S0, V),
    ( truthy(V)
    -> exec_stmt(Body, S0, S1),
       ( get_ctrl(S1, break)    -> set_ctrl(normal, S1, S)
       ; get_ctrl(S1, continue) -> set_ctrl(normal, S1, S2), exec_stmt(while(Cond, Body), S2, S)
       ; get_ctrl(S1, normal)   -> exec_stmt(while(Cond, Body), S1, S)
       ; S = S1
       )
    ; S = S0
    ).

exec_stmt(for(Var, Start, End, Dir, Body), S0, S) :-
    eval_expr(Start, S0, SV),
    eval_expr(End, S0, EV),
    set_var(Var, SV, S0, S1),
    for_loop(Var, SV, EV, Dir, Body, S1, S).

exec_stmt(repeat(Body, Cond), S0, S) :-
    exec_stmts(Body, S0, S1),
    eval_expr(Cond, S1, V),
    ( truthy(V) -> S = S1 ; exec_stmt(repeat(Body, Cond), S1, S) ).

exec_stmt(case(Expr, Arms, Else), S0, S) :-
    eval_expr(Expr, S0, V),
    ( select_arm(V, Arms, S0, ArmStmt)
    -> exec_stmt(ArmStmt, S0, S)
    ; exec_stmts(Else, S0, S)
    ).

exec_stmt(with(_Targets, Body), S0, S) :-
    % Lightweight WITH: execute body in current scope. A full implementation
    % would push a name resolution scope for each target.
    exec_stmt(Body, S0, S).

exec_stmt(try_except(Body, Handlers, Finally), S0, S) :-
    catch(exec_stmts(Body, S0, S1), _, exec_stmts(Handlers, S0, S1)),
    exec_stmts(Finally, S1, S).

exec_stmt(break,    S0, S) :- set_ctrl(break, S0, S).
exec_stmt(continue, S0, S) :- set_ctrl(continue, S0, S).
exec_stmt(exit,     S0, S) :- set_ctrl(exit, S0, S).
exec_stmt(exit_with(E), S0, S) :- eval_expr(E, S0, V), set_ctrl(exit_with(V), S0, S).

% Catch-all: leave a trace marker for unhandled statement shapes.
exec_stmt(Stmt, S0, S) :-
    format(atom(Line), "UNHANDLED ~w", [Stmt]),
    push_out(Line, S0, S).

for_loop(Var, Cur, End, Dir, Body, S0, S) :-
    ( Dir == up,   number(Cur), number(End), Cur =< End -> Continue = true
    ; Dir == down, number(Cur), number(End), Cur >= End -> Continue = true
    ; Continue = false
    ),
    ( Continue == true
    -> set_var(Var, Cur, S0, S1),
       exec_stmt(Body, S1, S2),
       ( get_ctrl(S2, break)    -> set_ctrl(normal, S2, S)
       ; ( get_ctrl(S2, continue) -> set_ctrl(normal, S2, S3) ; S3 = S2 ),
         ( Dir == up -> Next is Cur + 1 ; Next is Cur - 1 ),
         for_loop(Var, Next, End, Dir, Body, S3, S)
       )
    ; S = S0
    ).

select_arm(V, [arm(Labels, Stmt) | _], S, Stmt) :-
    member(L, Labels),
    eval_expr(L, S, LV),
    LV == V, !.
select_arm(V, [_ | Rest], S, Stmt) :- select_arm(V, Rest, S, Stmt).

truthy(true).
truthy(bool(true)).

%% ==========================================================================
%% Assignment dispatch
%% ==========================================================================

do_assign(ident(Name), V, S0, S) :- !,
    set_var(Name, V, S0, S).

% MyDataSet.FieldByName('foo').AsString := 'bar'
%   → SQL log: set_field on MyDataSet, field=foo, value=bar
do_assign(dot(call(dot(ident(DS), 'FieldByName'), [str(Field)]), _Conv), V, S0, S) :- !,
    sql_set_field(DS, Field, V, S0, S).

% MyDataSet.SomeField := 'bar'   → set_field
do_assign(dot(ident(DS), Field), V, S0, S) :- !,
    sql_set_field(DS, Field, V, S0, S).

do_assign(_, _, S, S).

%% ==========================================================================
%% Call dispatch
%% ==========================================================================

% Unwrap statements like `ShowMessage('x');` which the parser emits as
% call(call(ident('ShowMessage'), [str('x')]), []) due to primary_tail
% already absorbing the parenthesised args.
do_call(call(Inner, Args), [], S0, S) :- !, do_call(Inner, Args, S0, S).

% Recognised TDataSet/TSQLQuery operations: emit SQL log entries.
do_call(dot(ident(DS), 'Open'), _Args, S0, S)         :- !, sql_open(DS, '', S0, S).
do_call(dot(ident(DS), 'Close'), _, S0, S)            :- !, sql_close(DS, S0, S).
do_call(dot(ident(DS), 'Insert'), _, S0, S)           :- !, sql_insert(DS, S0, S).
do_call(dot(ident(DS), 'Edit'), _, S0, S)             :- !, sql_edit(DS, S0, S).
do_call(dot(ident(DS), 'Post'), _, S0, S)             :- !, sql_post(DS, S0, S).
do_call(dot(ident(DS), 'Delete'), _, S0, S)           :- !, sql_delete(DS, S0, S).
do_call(dot(ident(DS), 'ApplyUpdates'), _, S0, S)     :- !, sql_apply_updates(DS, S0, S).
do_call(dot(ident(DS), 'StartTransaction'), _, S0, S) :- !, sql_start_tx(DS, S0, S).
do_call(dot(ident(DS), 'Commit'), _, S0, S)           :- !, sql_commit(DS, S0, S).
do_call(dot(ident(DS), 'CommitRetaining'), _, S0, S)  :- !, sql_commit(DS, S0, S).
do_call(dot(ident(DS), 'Rollback'), _, S0, S)         :- !, sql_rollback(DS, S0, S).
do_call(dot(ident(DS), 'ExecSQL'), _, S0, S)          :- !, sql_exec_sql(DS, '', S0, S).

% ShowMessage / Writeln / similar — capture as out lines.
do_call(ident('ShowMessage'), [Arg], S0, S) :- !,
    eval_expr(Arg, S0, V),
    format(atom(Line), "MSG ~w", [V]),
    push_out(Line, S0, S).
do_call(ident('Writeln'), Args, S0, S) :- !,
    maplist([E, V] >> eval_expr(E, S0, V), Args, Vs),
    format(atom(Line), "OUT ~w", [Vs]),
    push_out(Line, S0, S).

% Method on this form / referenced object: invoke recursively.
do_call(dot(ident(Obj), Method), Args, S0, S) :-
    simulator_state:lookup_object(Obj, S0, object(_, _)), !,
    invoke_method(Obj, Method, Args, S0, S).

% Bare procedure call (e.g. Self method).
do_call(ident(Name), Args, S0, S) :-
    get_dict(current_form, S0, FormName), FormName \== none, !,
    catch(invoke_method(FormName, Name, Args, S0, S), _, S = S0).

% Anything else: record as an unhandled call so it shows up in the trace.
do_call(Callee, Args, S0, S) :-
    format(atom(Line), "CALL ~w(~w)", [Callee, Args]),
    push_out(Line, S0, S).
