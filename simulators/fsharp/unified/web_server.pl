%============================================================
% web_server.pl - Web UI for the F# Simulator
%
% Serves HTML pages showing F# source code, parsed AST,
% and interactive simulator execution.
%
% Static assets (CSS, JS) live in the web/ subdirectory.
%
% Usage:
%   swipl -l web_server.pl -g "start_server(8081)"
%
% Then open http://localhost:8081/ in a browser.
%============================================================

:- module(web_server, [
    start_server/1
]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/html_write)).
:- use_module(library(http/html_head)).
:- use_module(library(http/http_json)).
:- use_module(library(http/json)).
:- use_module(library(filesex)).

:- use_module(fsharp, [run_fsharp/2, exec_procedure/4]).
:- use_module(fsharp_parser, [parse_fsharp/2]).
:- use_module(fsharp_state).

%------------------------------------------------------------
% HTTP Routes
%------------------------------------------------------------

:- http_handler(root(.),       handle_index,   []).
:- http_handler(root(view),    handle_view,    []).
:- http_handler(root(run),     handle_run,     [method(post)]).
:- http_handler(root(api/parse), handle_api_parse, [method(post)]).
:- http_handler(root(api/run),   handle_api_run,   [method(post)]).
:- http_handler(root(static),   handle_static,  [prefix]).

%------------------------------------------------------------
% Server Start
%------------------------------------------------------------

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format("F# Simulator Web UI running at http://localhost:~w/~n", [Port]).

%------------------------------------------------------------
% Static File Serving
%------------------------------------------------------------

web_dir(Dir) :-
    source_file(web_server:start_server(_), ThisFile),
    file_directory_name(ThisFile, BaseDir),
    directory_file_path(BaseDir, web, Dir).

mime_type(css,  'text/css').
mime_type(js,   'application/javascript').
mime_type(html, 'text/html').

handle_static(Request) :-
    memberchk(path(Path), Request),
    atom_concat('/static/', RelPath, Path),
    web_dir(WebDir),
    directory_file_path(WebDir, RelPath, AbsPath),
    ( exists_file(AbsPath) ->
        file_name_extension(_, Ext, AbsPath),
        ( mime_type(Ext, ContentType) -> true ; ContentType = 'application/octet-stream' ),
        read_file_to_string(AbsPath, Content, []),
        format('Content-type: ~w~n~n', [ContentType]),
        write(Content)
    ;
        format('Content-type: text/plain~nStatus: 404~n~nNot found: ~w~n', [RelPath])
    ).

%------------------------------------------------------------
% File Discovery
%------------------------------------------------------------

fs_search_dirs(Dirs) :-
    Dirs = [
        '../../../clarion_projects/treatment-offset/fsharp-ddd/TreatmentOffset.Domain',
        '../../../clarion_projects/treatment-offset/fsharp-ddd/TreatmentOffset.Tests'
    ].

find_fs_files(Files) :-
    fs_search_dirs(Dirs),
    findall(File, (
        member(Dir, Dirs),
        absolute_file_name(Dir, AbsDir, [file_type(directory), access(exist), file_errors(fail)]),
        directory_files(AbsDir, Entries),
        member(Entry, Entries),
        file_name_extension(_, fs, Entry),
        directory_file_path(AbsDir, Entry, AbsPath),
        file_base_name(AbsDir, ParentDir),
        atomic_list_concat([ParentDir, '/', Entry], DisplayName),
        File = file(DisplayName, AbsPath)
    ), Files).

%------------------------------------------------------------
% Index Page
%------------------------------------------------------------

handle_index(_Request) :-
    find_fs_files(Files),
    reply_html_page(
        title('F# Simulator'),
        [ \html_head_extras,
          div(class(container), [
            h1('F# Simulator'),
            p(class(subtext), 'Select an .fs file or write F# code in the editor.'),
            div(class(panels), [
                div(class(panel), [
                    div(class('panel-header'), 'F# Files'),
                    ul(class('file-list'), \file_list(Files))
                ]),
                div(class(panel), [
                    div(class('panel-header'), 'Code Editor'),
                    \editor_panel
                ])
            ])
          ]),
          script([src('/static/editor.js')], [])
        ]).

html_head_extras -->
    html(link([rel(stylesheet), href('/static/style.css')])).

file_list([]) --> [].
file_list([file(Display, Path)|Rest]) -->
    { format(atom(Href), '/view?file=~w', [Path]) },
    html(li(a([href(Href)], Display))),
    file_list(Rest).

editor_panel -->
    html([
        textarea([class('code-editor'), id(editor)],
'let add x y = x + y\nlet result = add 5 10\n'),
        div(class('editor-actions'), [
            button([class('run-btn'), onclick('parseEditor()')], 'Parse AST'),
            button([class('run-btn'), onclick('runEditor()')], 'Run...')
        ]),
        div([id('editor-ast'), class('run-output')], '')
    ]).

%------------------------------------------------------------
% View Page
%------------------------------------------------------------

handle_view(Request) :-
    http_parameters(Request, [file(FilePath, [])]),
    ( exists_file(FilePath) ->
        read_file_to_string(FilePath, Source, []),
        file_base_name(FilePath, FileName),
        ( catch(parse_fsharp(Source, AST), ParseErr, (AST = error(ParseErr))) -> true ; AST = error(parse_failed) ),
        ( AST \= error(_), AST = program(Bindings) ->
            findall(Name, member(let(Name, Args, _), Bindings), BindNames)
        ; BindNames = []
        ),
        reply_html_page(
            title(FileName),
            [ \html_head_extras,
              div(class(container), [
                div(class(nav), [ a(href('/'), 'Back to files') ]),
                h1(FileName),
                \run_section(BindNames),
                div(class(panels), [
                    div(class(panel), [
                        div(class('panel-header'), 'Source'),
                        pre(\highlight_source(Source))
                    ]),
                    div(class(panel), [
                        div(class('panel-header'), 'AST'),
                        pre(class(ast), \format_ast(AST, 0))
                    ])
                ]),
                \file_path_script(FilePath)
              ]),
              script([src('/static/view.js')], [])
            ])
    ;
        reply_html_page(title('Not Found'), [h1('File not found'), p(FilePath)])
    ).

file_path_script(FilePath) -->
    { format(atom(JS), 'window.__filePath = "~w";', [FilePath]) },
    html(script([], JS)).

run_section(ProcNames) -->
    { ProcNames \= [] },
    !,
    html(div(class('run-section'), [
        div(class('run-form'), [
            label(for(proc), 'Call:'),
            select([id(proc), name(proc)], \proc_options(ProcNames)),
            label(for(args), 'Args:'),
            input([id(args), name(args), type(text), placeholder('e.g. 5 10'), size(20)]),
            button([class('run-btn'), onclick('runProcedure()')], 'Run')
        ]),
        div([id('run-output'), class('run-output')], '')
    ])).
run_section(_) --> [].

proc_options([]) --> [].
proc_options([Name|Rest]) -->
    html(option([value(Name)], Name)),
    proc_options(Rest).

%------------------------------------------------------------
% API Endpoints
%------------------------------------------------------------

handle_api_parse(Request) :-
    http_read_json_dict(Request, Dict),
    Source = Dict.source,
    ( catch(
        ( parse_fsharp(Source, AST),
          term_to_ast_string(AST, ASTStr),
          Reply = json{status: ok, simple_ast: ASTStr, bridged_ast: ASTStr} % No bridge for F# yet
        ),
        Err,
        ( term_string(Err, ErrStr), Reply = json{status: error, message: ErrStr} )
      ) -> true
    ; Reply = json{status: error, message: "Parse failed"}
    ),
    reply_json_dict(Reply).

handle_api_run(Request) :-
    http_read_json_dict(Request, Dict),
    ( get_dict(source, Dict, Source) -> true
    ; get_dict(file, Dict, FilePath),
      read_file_to_string(FilePath, Source, [])
    ),
    ProcName = Dict.procedure,
    ArgsRaw = Dict.get(args, []),
    ( is_list(ArgsRaw) -> ArgsList = ArgsRaw
    ; atom_string(ArgsRaw, ArgsStr),
      ( ArgsStr == "" -> ArgsList = []
      ; split_string(ArgsStr, " ", " ", ArgParts), % F# uses space
        maplist(parse_arg, ArgParts, ArgsList)
      )
    ),
    atom_string(ProcAtom, ProcName),
    ( catch(
        ( exec_procedure(Source, ProcAtom, ArgsList, Result),
          term_string(Result, ResultStr),
          Reply = json{status: ok, result: ResultStr}
        ),
        Err,
        ( term_string(Err, ErrStr), Reply = json{status: error, message: ErrStr} )
      ) -> true
    ; Reply = json{status: error, message: "Execution failed"}
    ),
    reply_json_dict(Reply).

handle_run(Request) :- handle_api_run(Request).

parse_arg(S, N) :- number_string(N, S), !.
parse_arg(S, A) :- atom_string(A, S).

term_to_ast_string(Term, String) :-
    with_output_to(string(String),
        print_term(Term, [output(current_output), right_margin(100)])).

%------------------------------------------------------------
% Syntax Highlighting (F#)
%------------------------------------------------------------

highlight_source(Source) -->
    { split_string(Source, "\n", "", Lines),
      length(Lines, NumLines),
      numlist(1, NumLines, LineNums),
      pairs_keys_values(Pairs, LineNums, Lines) },
    highlight_lines(Pairs).

highlight_lines([]) --> [].
highlight_lines([N-Line|Rest]) -->
    { format(atom(NumStr), "~d", [N]) },
    html([span(class('line-num'), NumStr), \highlight_line(Line), '\n']),
    highlight_lines(Rest).

highlight_line(Line) -->
    { string_codes(Line, Codes),
      tokenize_line(Codes, Tokens) },
    emit_tokens(Tokens).

emit_tokens([]) --> [].
emit_tokens([Token|Rest]) -->
    html(\emit_token(Token)),
    emit_tokens(Rest).

emit_token(kw(Text)) --> html(span(class(kw), Text)).
emit_token(comment(Text)) --> html(span(class(comment), Text)).
emit_token(str(Text)) --> html(span(class(str), Text)).
emit_token(num(Text)) --> html(span(class(num), Text)).
emit_token(op(Text)) --> html(span(class(op), Text)).
emit_token(plain(Text)) --> html(Text).

tokenize_line([], []).
tokenize_line(Codes, Tokens) :-
    Codes = [C|Rest],
    ( C =:= 0'/ , Rest = [0'/|_] -> string_codes(S, Codes), Tokens = [comment(S)]
    ; C =:= 0'" -> take_string(Codes, StrCodes, RestC), string_codes(S, StrCodes), tokenize_line(RestC, RestTokens), Tokens = [str(S)|RestTokens]
    ; is_alpha(C) -> take_word(Codes, WordCodes, RestC), string_codes(Word, WordCodes), classify_word(Word, Token), tokenize_line(RestC, RestTokens), Tokens = [Token|RestTokens]
    ; is_digit(C) -> take_number(Codes, NumCodes, RestC), string_codes(S, NumCodes), tokenize_line(RestC, RestTokens), Tokens = [num(S)|RestTokens]
    ; memberchk(C, [0'+, 0'-, 0'*, 0'/, 0'=, 0'<, 0'>, 0'(, 0'), 0',, 0'|]) ->
        char_code(Ch, C), atom_string(Ch, ChStr), tokenize_line(Rest, RestTokens), Tokens = [op(ChStr)|RestTokens]
    ; char_code(Ch, C), atom_string(Ch, ChStr), tokenize_line(Rest, RestTokens), Tokens = [plain(ChStr)|RestTokens]
    ).

take_word([], [], []).
take_word([C|Cs], [C|Ws], Rest) :- (char_type(C, alnum); C =:= 0'_), !, take_word(Cs, Ws, Rest).
take_word(Codes, [], Codes).

take_number([], [], []).
take_number([C|Cs], [C|Ns], Rest) :- char_type(C, digit), !, take_number(Cs, Ns, Rest).
take_number(Codes, [], Codes).

take_string([0'"|Cs], [0'"|Ss], Rest) :- take_string_inner(Cs, Ss, Rest).
take_string_inner([], [], []).
take_string_inner([0'"|Cs], [0'"], Cs) :- !.
take_string_inner([C|Cs], [C|Ss], Rest) :- take_string_inner(Cs, Ss, Rest).

classify_word(Word, Token) :-
    ( is_keyword(Word) -> Token = kw(Word) ; Token = plain(Word) ).

is_keyword(W) :- memberchk(W, ["let", "in", "if", "then", "else", "match", "with", "type", "module", "open", "rec", "mutable"]).

%------------------------------------------------------------
% AST Pretty-Printer (HTML)
%------------------------------------------------------------

format_ast(error(Err), _Indent) --> !, { term_string(Err, ErrStr) }, html(span(class('run-error'), ['Error: ', ErrStr])).
format_ast(Term, Indent) -->
    { compound(Term), \+ is_list(Term), \+ string(Term) }, !,
    { Term =.. [Functor|Args], NextIndent is Indent + 1 },
    html(span(class('ast-functor'), Functor)),
    ( { Args = [] } -> html('') ; format_ast_args(Args, NextIndent) ).
format_ast(List, Indent) --> { is_list(List) }, !, format_ast_list(List, Indent).
format_ast(N, _) --> { number(N) }, !, { term_string(N, NS) }, html(span(class('ast-number'), NS)).
format_ast(A, _) --> { atom(A) }, !, { atom_string(A, AS) }, html(span(class('ast-atom'), AS)).
format_ast(S, _) --> { string(S) }, !, { format(atom(Quoted), '"~w"', [S]) }, html(span(class('ast-atom'), Quoted)).
format_ast(T, _) --> { term_string(T, TS) }, html(TS).

format_ast_args([], _) --> [].
format_ast_args(Args, Indent) -->
    html('('),
    ( { length(Args, Len), Len =< 2, all_simple(Args) } -> format_ast_inline(Args, Indent)
    ; html('\n'), format_ast_indented(Args, Indent) ),
    html(')').

format_ast_inline([], _) --> [].
format_ast_inline([Arg], Indent) --> format_ast(Arg, Indent).
format_ast_inline([Arg|Rest], Indent) --> { Rest \= [] }, format_ast(Arg, Indent), html(', '), format_ast_inline(Rest, Indent).

format_ast_indented([], _) --> [].
format_ast_indented([Arg], Indent) --> indent_html(Indent), format_ast(Arg, Indent), html('\n').
format_ast_indented([Arg|Rest], Indent) --> { Rest \= [] }, indent_html(Indent), format_ast(Arg, Indent), html(',\n'), format_ast_indented(Rest, Indent).

format_ast_list([], _) --> html(span(class('ast-list'), '[]')).
format_ast_list(List, Indent) -->
    { length(List, Len), Len =< 3, all_simple(List) }, !,
    html(span(class('ast-list'), '[')), format_ast_inline(List, Indent), html(span(class('ast-list'), ']')).
format_ast_list(List, Indent) -->
    { NextIndent is Indent + 1 }, html(span(class('ast-list'), '[\n')),
    format_ast_indented(List, NextIndent), indent_html(Indent), html(span(class('ast-list'), ']')).

all_simple([]).
all_simple([X|Xs]) :- (atom(X) ; number(X) ; string(X)), all_simple(Xs).

indent_html(0) --> !.
indent_html(N) --> { N > 0, N1 is N - 1 }, html('  '), indent_html(N1).

%------------------------------------------------------------
% Standalone entry point
%------------------------------------------------------------

:- initialization((
    current_prolog_flag(argv, Argv),
    ( Argv = [PortAtom|_] -> atom_number(PortAtom, Port) ; Port = 8081 ),
    start_server(Port)
), main).
