:- use_module(clarion_parser).
:- use_module(clarion_html).

test_gen(File, OutFile) :-
    read_file_to_codes(File, Codes, []),
    parse_clarion(Codes, program(_Files, _Groups, Globals, _Map, _Procs)),
    ( member(window(Name, Title, Attrs, Controls), Globals) -> true
    ; format('ERROR: No window declaration found in ~w~n', [File]), fail
    ),
    format('Generating HTML for window ~w: ~w~n', [Name, Title]),
    phrase(window_to_html(window(Name, Title, Attrs, Controls)), HTML),
    open(OutFile, write, Stream),
    format(Stream, '~s', [HTML]),
    close(Stream),
    format('Successfully wrote ~w~n', [OutFile]).

main :-
    test_gen('../../../clarion_projects/html_gen_demo/simple_form.clw', 'simple_form.html'),
    test_gen('../../../clarion_projects/html_gen_demo/complex_form.clw', 'complex_form.html'),
    halt.
