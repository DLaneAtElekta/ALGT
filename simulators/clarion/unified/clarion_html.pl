:- module(clarion_html, [window_to_html//1]).

:- set_prolog_flag(double_quotes, codes).

window_to_html(window(_Name, Title, Attrs, Controls)) -->
    "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"UTF-8\">\n<title>",
    atom_codes_dcg(Title),
    "</title>\n",
    "<style>\n",
    "  body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f0f0; padding: 20px; }\n",
    "  .window { ",
    "    position: relative; ",
    "    border: 1px solid #999; ",
    "    background-color: #e0e0e0; ",
    "    box-shadow: 4px 4px 10px rgba(0,0,0,0.3); ",
    "    margin: 0 auto; ",
    "    overflow: hidden; ",
    "  }\n",
    "  .window-title { ",
    "    background-color: #0078d7; ",
    "    color: white; ",
    "    padding: 5px 10px; ",
    "    font-weight: bold; ",
    "    font-size: 14px; ",
    "    height: 25px; ",
    "    box-sizing: border-box; ",
    "  }\n",
    "  .window-content { position: relative; width: 100%; height: calc(100% - 25px); }\n",
    "  .control { position: absolute; font-size: 12px; box-sizing: border-box; }\n",
    "  .prompt { text-align: left; vertical-align: middle; line-height: 1.2; }\n",
    "  .entry { border: 1px solid #ccc; padding: 2px; background: white; }\n",
    "  .button { background-color: #eee; border: 1px solid #777; cursor: pointer; text-align: center; }\n",
    "  .button:hover { background-color: #ddd; }\n",
    "  .string { color: #333; }\n",
    "  .list { border: 1px solid #ccc; background: white; }\n",
    "  .check-container { display: flex; align-items: center; }\n",
    "  .check-label { margin-left: 5px; white-space: nowrap; }\n",
    "  .group { border: 1px solid #aaa; border-radius: 3px; }\n",
    "  .group-title { position: absolute; top: -10px; left: 10px; background: #e0e0e0; padding: 0 5px; font-size: 11px; color: #555; }\n",
    "</style>\n</head>\n<body>\n",
    { window_dims(Attrs, W, H) },
    "<div class=\"window\" style=\"width: ", number_codes_dcg(W), "px; height: ", number_codes_dcg(H), "px;\">\n",
    "  <div class=\"window-title\">", atom_codes_dcg(Title), "</div>\n",
    "  <div class=\"window-content\">\n",
    controls_to_html(Controls),
    "  </div>\n",
    "</div>\n</body>\n</html>\n".

window_dims(Attrs, W, H) :-
    ( member(at(_, _, W0, H0), Attrs) -> W is W0 * 2, H is H0 * 2
    ; W = 600, H = 400
    ).

controls_to_html([]) --> [].
controls_to_html([C|Cs]) -->
    control_to_html(C),
    controls_to_html(Cs).

control_to_html(prompt(Text, Attrs)) -->
    { attr_style(Attrs, Style) },
    "<label class=\"control prompt\" style=\"", atom_codes_dcg(Style), "\">",
    atom_codes_dcg(Text), "</label>\n".

control_to_html(entry(_Format, Attrs, _UseVar)) -->
    { attr_style(Attrs, Style) },
    "<input class=\"control entry\" type=\"text\" style=\"", atom_codes_dcg(Style), "\">\n".

control_to_html(button(Text, Attrs, _UseRef)) -->
    { attr_style(Attrs, Style) },
    "<button class=\"control button\" style=\"", atom_codes_dcg(Style), "\">",
    { clean_text(Text, Clean) },
    atom_codes_dcg(Clean), "</button>\n".

control_to_html(string_ctl(Text, Attrs, _UseVar)) -->
    { attr_style(Attrs, Style) },
    "<span class=\"control string\" style=\"", atom_codes_dcg(Style), "\">",
    atom_codes_dcg(Text), "</span>\n".

control_to_html(list_ctl(Attrs, _UseRef, _Drop, Items)) -->
    { attr_style(Attrs, Style) },
    "<select class=\"control list\" style=\"", atom_codes_dcg(Style), "\">\n",
    options_to_html(Items),
    "</select>\n".

control_to_html(check(Text, Attrs, _UseVar)) -->
    { attr_style(Attrs, Style) },
    "<div class=\"control check-container\" style=\"", atom_codes_dcg(Style), "\">\n",
    "  <input type=\"checkbox\">\n",
    "  <label class=\"check-label\">", atom_codes_dcg(Text), "</label>\n",
    "</div>\n".

control_to_html(group_ctl(Text, Attrs, Controls)) -->
    { attr_style(Attrs, Style) },
    "<div class=\"control group\" style=\"", atom_codes_dcg(Style), "\">\n",
    ( { Text \= '' } -> "  <div class=\"group-title\">", atom_codes_dcg(Text), "</div>\n" ; [] ),
    "</div>\n",
    controls_to_html(Controls).

options_to_html([]) --> [].
options_to_html([I|Is]) -->
    "  <option>", atom_codes_dcg(I), "</option>\n",
    options_to_html(Is).

attr_style(Attrs, Style) :-
    ( member(at(X, Y, W, H), Attrs) ->
        format(atom(Style), "left:~dpx; top:~dpx; width:~dpx; height:~dpx;", [X*2, Y*2, W*2, H*2])
    ; member(at(X, Y), Attrs) ->
        format(atom(Style), "left:~dpx; top:~dpx;", [X*2, Y*2])
    ; Style = ''
    ).

clean_text(Text, Clean) :-
    atom_codes(Text, Codes),
    exclude(=(0'&), Codes, CleanCodes),
    atom_codes(Clean, CleanCodes).

atom_codes_dcg(Atom) -->
    { ( atom(Atom) -> atom_codes(Atom, Codes) ; Codes = Atom ) },
    Codes.

number_codes_dcg(Number) -->
    { number_codes(Number, Codes) },
    Codes.
