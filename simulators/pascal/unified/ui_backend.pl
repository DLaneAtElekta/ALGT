% ui_backend.pl — Stub UI backend for Lazarus TForm event handling.
%
% This is a headless backend: it accepts events from a queue, looks up the
% matching event handler on the target form, and drives the simulator to
% execute the handler's body. GUI events are recorded as labels in the
% execution trace alongside SQL log entries.

:- module(ui_backend, [
    deliver_event/3        % deliver_event(+Event, +S0, -S)
]).

:- use_module(simulator_state, [
    lookup_form/3,
    push_out/3
]).

% Event = click(FormName, ControlName)
%       | change(FormName, ControlName, Value)
%       | select(FormName, ControlName, Index)
%       | open(FormName)
%       | close(FormName)
%
% deliver_event/3 records the event and emits a marker line; actual handler
% execution is wired up in simulator.pl, which knows how to bind Sender and
% invoke the method.

deliver_event(Event, S0, S) :-
    format(atom(Line), "UI ~w", [Event]),
    push_out(Line, S0, S).
