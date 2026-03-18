:- module(fsharp_state, [
    empty_state/1,
    get_var/3,
    set_var/4,
    push_frame/2,
    pop_frame/2,
    bind_args/4
]).

:- use_module(library(assoc)).

%% state(Globals, Frames)
% Globals: assoc Name -> Value
% Frames: list of assocs (local scopes)

empty_state(state(Globals, [])) :-
    empty_assoc(Globals).

get_var(Name, state(Globals, Frames), Value) :-
    (   find_in_frames(Name, Frames, Value)
    ->  true
    ;   get_assoc(Name, Globals, Value)
    ).

find_in_frames(Name, [Frame|Rest], Value) :-
    (   get_assoc(Name, Frame, Value)
    ->  true
    ;   find_in_frames(Name, Rest, Value)
    ).

set_var(Name, Value, state(Globals, Frames), state(NewGlobals, Frames)) :-
    put_assoc(Name, Globals, Value, NewGlobals).

push_frame(state(Globals, Frames), state(Globals, [NewFrame|Frames])) :-
    empty_assoc(NewFrame).

pop_frame(state(Globals, [_|Frames]), state(Globals, Frames)).

bind_args([], [], State, State).
bind_args([Name|Ns], [Val|Vs], state(Globals, [Frame|Fs]), StateOut) :-
    put_assoc(Name, Frame, Val, NewFrame),
    bind_args(Ns, Vs, state(Globals, [NewFrame|Fs]), StateOut).
