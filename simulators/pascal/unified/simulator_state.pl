% simulator_state.pl — Mutable state for the Pascal simulator.
%
% State shape (a flat dict):
%   state{
%     vars:    Vars,           % flat name → value map for current scope
%     globals: Globals,        % unit-level globals
%     classes: Classes,        % atom(Name) → class(Members, Methods, Parent)
%     forms:   Forms,          % atom(Name) → form_runtime(Class, Props, Children)
%     objects: Objects,        % atom(InstanceName) → object(Class, Fields)
%     log:     Log,            % SQL transaction log (reverse-ordered list of entries)
%     ui:      UI,             % UI event queue and state
%     out:     Out,            % captured stdout-like output
%     ctrl:    Ctrl            % normal | break | continue | exit | exit_with(V)
%   }

:- module(simulator_state, [
    empty_state/1,
    get_var/3,
    set_var/4,
    get_global/3,
    set_global/4,
    register_class/6,
    lookup_class/3,
    register_form/5,
    lookup_form/3,
    register_object/5,
    lookup_object/3,
    update_object/4,
    append_log/3,
    log_entries/2,
    push_event/3,
    pop_event/3,
    set_ctrl/3,
    get_ctrl/2,
    push_out/3,
    get_out/2
]).

empty_state(state{
    vars:    _{},
    globals: _{},
    classes: _{},
    forms:   _{},
    objects: _{},
    log:     [],
    ui:      ui{events: [], current: none},
    out:     [],
    ctrl:    normal
}).

get_var(Name, S, Value) :-
    ( get_dict(Name, S.vars, V)    -> Value = V
    ; get_dict(Name, S.globals, V) -> Value = V
    ; Value = unbound
    ).

set_var(Name, Value, S0, S) :-
    Vars0 = S0.vars,
    put_dict(Name, Vars0, Value, Vars),
    S = S0.put(vars, Vars).

get_global(Name, S, Value) :-
    get_dict(Name, S.globals, Value).

set_global(Name, Value, S0, S) :-
    G0 = S0.globals,
    put_dict(Name, G0, Value, G),
    S = S0.put(globals, G).

register_class(Name, Parent, Members, Methods, S0, S) :-
    Classes0 = S0.classes,
    put_dict(Name, Classes0, class_rt(Parent, Members, Methods), Classes),
    S = S0.put(classes, Classes).

lookup_class(Name, S, Class) :-
    get_dict(Name, S.classes, Class).

register_form(Name, Class, Form, S0, S) :-
    Forms0 = S0.forms,
    put_dict(Name, Forms0, form_rt(Class, Form), Forms),
    S = S0.put(forms, Forms).

lookup_form(Name, S, Form) :-
    get_dict(Name, S.forms, Form).

register_object(Name, Class, Fields, S0, S) :-
    Objs0 = S0.objects,
    put_dict(Name, Objs0, object(Class, Fields), Objs),
    S = S0.put(objects, Objs).

lookup_object(Name, S, Object) :-
    get_dict(Name, S.objects, Object).

update_object(Name, Fields, S0, S) :-
    Objs0 = S0.objects,
    get_dict(Name, Objs0, object(Class, _)),
    put_dict(Name, Objs0, object(Class, Fields), Objs),
    S = S0.put(objects, Objs).

append_log(Entry, S0, S) :-
    Log0 = S0.log,
    S = S0.put(log, [Entry | Log0]).

log_entries(S, Entries) :-
    reverse(S.log, Entries).

push_event(Event, S0, S) :-
    UI0 = S0.ui,
    Events0 = UI0.events,
    append(Events0, [Event], Events),
    UI = UI0.put(events, Events),
    S = S0.put(ui, UI).

pop_event(Event, S0, S) :-
    UI0 = S0.ui,
    UI0.events = [Event | Rest],
    UI = UI0.put(events, Rest),
    S = S0.put(ui, UI).

set_ctrl(Ctrl, S0, S) :- S = S0.put(ctrl, Ctrl).
get_ctrl(S, Ctrl)     :- Ctrl = S.ctrl.

push_out(Line, S0, S) :-
    Out0 = S0.out,
    S = S0.put(out, [Line | Out0]).

get_out(S, Lines) :-
    reverse(S.out, Lines).
