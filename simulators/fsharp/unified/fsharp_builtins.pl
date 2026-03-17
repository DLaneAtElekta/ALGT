:- module(fsharp_builtins, [
    is_builtin/1,
    call_builtin/4
]).

is_builtin(printfn).

call_builtin(printfn, [Format|Args], State, State) :-
    % Simplified printfn
    format(Format, Args),
    nl.
