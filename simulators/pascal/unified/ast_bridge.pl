% ast_bridge.pl — Translate Pascal parser AST + LFM AST into the
% simulator's executable AST.
%
% Input:
%   Unit  = unit(Name, interface(IUses, IDecls), implementation(IUses, IDecls), Init)
%   Form  = form(Name, Class, Properties, Children)        % from lfm_parser
%
% Output:
%   module(UnitName, Classes, Forms, Procedures, Init)
%     Classes    = [class(Name, Parent, Members, MethodDefs), ...]
%     Forms      = [form(Name, Class, Properties, Children), ...]
%     Procedures = [proc(Kind, Name, Params, Ret, Locals, Body), ...]
%     Init       = [Stmt, ...] | []

:- module(ast_bridge, [
    bridge_unit/3      % bridge_unit(+UnitAST, +FormASTs, -ModuleAST)
]).

bridge_unit(unit(UnitName, IfaceSec, ImplSec, InitSec), FormASTs, Module) :-
    IfaceSec = interface(_, IDecls),
    ImplSec  = implementation(_, MDecls),
    append(IDecls, MDecls, AllDecls),
    collect_classes(AllDecls, ClassDecls),
    collect_methods(AllDecls, MethodDefs),
    attach_methods(ClassDecls, MethodDefs, Classes),
    collect_procs(AllDecls, Procs),
    init_stmts(InitSec, InitStmts),
    Module = module(UnitName, Classes, FormASTs, Procs, InitStmts).

collect_classes([], []).
collect_classes([type_decl(Name, class_type(Parent, Members)) | Rest], [class(Name, Parent, Members, []) | Cs]) :- !,
    collect_classes(Rest, Cs).
collect_classes([_ | Rest], Cs) :- collect_classes(Rest, Cs).

collect_methods([], []).
collect_methods([method_def(Class, Kind, Name, Params, Ret, Locals, Body) | Rest],
                [method(Class, Kind, Name, Params, Ret, Locals, Body) | Ms]) :- !,
    collect_methods(Rest, Ms).
collect_methods([_ | Rest], Ms) :- collect_methods(Rest, Ms).

collect_procs([], []).
collect_procs([proc_def(Kind, Name, Params, Ret, Locals, Body) | Rest],
              [proc(Kind, Name, Params, Ret, Locals, Body) | Ps]) :- !,
    collect_procs(Rest, Ps).
collect_procs([_ | Rest], Ps) :- collect_procs(Rest, Ps).

attach_methods([], _, []).
attach_methods([class(Name, Parent, Members, _) | Cs], AllMethods,
               [class(Name, Parent, Members, ClassMethods) | Out]) :-
    include(method_for_class(Name), AllMethods, ClassMethods),
    attach_methods(Cs, AllMethods, Out).

method_for_class(ClassName, method(ClassName, _, _, _, _, _, _)).

init_stmts(none, []).
init_stmts(init(Stmts), Stmts).
