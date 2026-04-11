%% =============================================================================
%% form_registry.pl — Form Type Registry
%% =============================================================================

:- module(form_registry, [
    form_step/6,
    form_available_events/3,
    registered_forms/1
]).

:- use_module(form_incrementer, []).
:- use_module(form_doubler, []).

%% form_step(+FormType, +Event, +FS0, -FS1, +DB0, -DB1)
form_step(incrementer, Event, FS0, FS1, DB0, DB1) :-
    form_incrementer:form_step(Event, FS0, FS1, DB0, DB1).
form_step(doubler, Event, FS0, FS1, DB0, DB1) :-
    form_doubler:form_step(Event, FS0, FS1, DB0, DB1).

%% form_available_events(+FormType, +FS, -Events)
form_available_events(incrementer, FS, Events) :-
    form_incrementer:available_events(FS, Events).
form_available_events(doubler, FS, Events) :-
    form_doubler:available_events(FS, Events).

registered_forms([incrementer, doubler]).
