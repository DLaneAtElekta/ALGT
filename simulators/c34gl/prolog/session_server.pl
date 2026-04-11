%% =============================================================================
%% session_server.pl — c34gl HTTP REST API + MCP Tool Definitions
%% =============================================================================
%%
%% Exposes the c34gl engine as a REST API on port 8183.
%%
%% Endpoints:
%% POST /api/c34gl/sessions → create session
%% GET /api/c34gl/sessions/:id → get full state
%% POST /api/c34gl/sessions/:id/step/:formId → step one form
%% POST /api/c34gl/sessions/:id/reset → reset to initial
%% GET /api/c34gl/sessions/:id/tape → tape only
%% GET /api/c34gl/sessions/:id/tables/:table → materialized table
%% DELETE /api/c34gl/sessions/:id → destroy
%%
%% Usage:
%% $ cd ALGT/simulators/c34gl/prolog
%% $ swipl session_server.pl
%% Server starts automatically on port 8183.
%% =============================================================================

:- module(session_server, [start_server/1, stop_server/0]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_parameters)).
:- use_module(library(uuid)).
:- use_module(library(lists)).
:- use_module(library(apply)).

:- use_module(c34gl_engine, [
    initial_state/1, step_form/4, materialize_table/3,
    tape_entries/2, get_form/3, available_events/3, reset_state/2
]).
:- use_module(form_registry, [registered_forms/1]).


%% =============================================================================
%% Session Storage
%% =============================================================================

:- dynamic session_state/2. %% session_state(SessionId, C34glState)

new_session(SessionId, State) :-
    uuid(SessionId),
    c34gl_engine:initial_state(State),
    assert(session_state(SessionId, State)).

get_session(SessionId, State) :-
    session_state(SessionId, State), !.
get_session(_, _) :-
    throw(http_reply(not_found(session))).

update_session(SessionId, NewState) :-
    retract(session_state(SessionId, _)), !,
    assert(session_state(SessionId, NewState)).

destroy_session(SessionId) :-
    retractall(session_state(SessionId, _)).


%% =============================================================================
%% Server Start/Stop
%% =============================================================================

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format("~`=t~60|~n", []),
    format(" c34gl server on http://localhost:~w~n", [Port]),
    format(" UI: http://localhost:~w/static/index.html~n", [Port]),
    format(" CORS enabled~n", []),
    format("~`=t~60|~n", []).

stop_server :- http_stop_server(8183, []).

:- set_setting(http:cors, [*]).


%% =============================================================================
%% Logging
%% =============================================================================

log(Fmt, Args) :-
    get_time(Now),
    stamp_date_time(Now, DateTime, local),
    DateTime = date(_,_,_,H,M,S,_,_,_),
    Si is truncate(S),
    format(user_error, "[~|~`0t~d~2+:~|~`0t~d~2+:~|~`0t~d~2+] ", [H, M, Si]),
    format(user_error, Fmt, Args),
    nl(user_error),
    flush_output(user_error).


%% =============================================================================
%% HTTP Handlers
%% =============================================================================

:- http_handler(root(api/c34gl/sessions), handle_sessions, [prefix]).

%% Static file serving
:- use_module(library(http/http_files)).

:- http_handler(root(static), serve_static, [prefix]).

serve_static(Request) :-
    source_file(session_server:start_server(_), SrcFile),
    file_directory_name(SrcFile, SrcDir),
    atom_concat(SrcDir, '/../web/static', StaticDir),
    http_reply_from_files(StaticDir, [], Request).

%% Session request dispatcher
handle_sessions(Request) :-
    cors_enable(Request,
        [methods([get, post, patch, put, delete, options])]),
    memberchk(method(Method), Request),
    memberchk(path(Path), Request),
    atom_string(Path, PathStr),
    split_string(PathStr, "/", "/", Parts),
    ( append(["api","c34gl","sessions"], Tail, Parts)
    -> catch(
        route(Method, Tail, Request),
        Error,
        handle_error(Error)
    )
    ; reply_json_dict(_{error: "Bad path"}, [status(404)])
    ).

handle_error(http_reply(Status)) :- !,
    reply_json_dict(_{error: Status}, [status(404)]).
handle_error(Error) :-
    format(atom(Msg), "~w", [Error]),
    reply_json_dict(_{error: Msg}, [status(500)]).


%% =============================================================================
%% Routes
%% =============================================================================

%% OPTIONS (CORS preflight)
route(options, _, _) :-
    format('Content-type: text/plain~n~n').

%% POST /sessions — create
route(post, [], _Request) :-
    new_session(SessionId, State),
    log("NEW ~w", [SessionId]),
    state_to_json(SessionId, State, Json),
    reply_json_dict(Json).

%% GET /sessions/:id — full state
route(get, [IdStr], _Request) :-
    atom_string(Id, IdStr),
    get_session(Id, State),
    state_to_json(Id, State, Json),
    reply_json_dict(Json).

%% POST /sessions/:id/step/:formId — step one form
route(post, [IdStr, "step", FormIdStr], Request) :-
    atom_string(Id, IdStr),
    atom_string(FormId, FormIdStr),
    http_read_json_dict(Request, Body),
    atom_string(Event, Body.event),
    get_session(Id, S0),
    ( c34gl_engine:step_form(FormId, Event, S0, S1)
    -> update_session(Id, S1),
        log("STEP ~w ~w:~w step=~w", [Id, FormId, Event, S1.step_count]),
        state_to_json(Id, S1, Json),
        reply_json_dict(Json)
    ; reply_json_dict(_{error: "Invalid step", formId: FormIdStr, event: Body.event},
        [status(422)])
    ).

%% POST /sessions/:id/reset — reset
route(post, [IdStr, "reset"], _Request) :-
    atom_string(Id, IdStr),
    get_session(Id, S0),
    c34gl_engine:reset_state(S0, S1),
    update_session(Id, S1),
    log("RESET ~w", [Id]),
    state_to_json(Id, S1, Json),
    reply_json_dict(Json).

%% GET /sessions/:id/tape — tape only
route(get, [IdStr, "tape"], _Request) :-
    atom_string(Id, IdStr),
    get_session(Id, State),
    tape_to_json(State, TapeJson),
    reply_json_dict(_{sessionId: Id, tape: TapeJson}).

%% GET /sessions/:id/tables/:table — materialized table
route(get, [IdStr, "tables", TableStr], _Request) :-
    atom_string(Id, IdStr),
    atom_string(Table, TableStr),
    get_session(Id, State),
    c34gl_engine:materialize_table(State, Table, Rows),
    reply_json_dict(_{sessionId: Id, table: Table, rows: Rows}).

%% DELETE /sessions/:id — destroy
route(delete, [IdStr], _Request) :-
    atom_string(Id, IdStr),
    destroy_session(Id),
    log("DELETE ~w", [Id]),
    reply_json_dict(_{ok: true}).


%% =============================================================================
%% JSON Serialization
%% =============================================================================

state_to_json(SessionId, State, Json) :-
    tape_to_json(State, TapeJson),
    forms_to_json(State, FormsJson),
    tables_to_json(State, TablesJson),
    Json = _{
        sessionId: SessionId,
        stepCount: State.step_count,
        tape: TapeJson,
        forms: FormsJson,
        tables: TablesJson
    }.

tape_to_json(State, TapeJson) :-
    c34gl_engine:tape_entries(State, Entries),
    maplist(tape_entry_to_json, Entries, TapeJson).

tape_entry_to_json(E, Json) :-
    Json = _{
        txId: E.tx_id,
        spid: E.spid,
        op: E.op,
        table: E.table,
        summary: E.summary
    }.

forms_to_json(State, FormsJson) :-
    dict_pairs(State.forms, _, Pairs),
    maplist(form_pair_to_json(State), Pairs, FormJsonPairs),
    dict_pairs(FormsJson, forms, FormJsonPairs).

form_pair_to_json(State, FormId-FS, FormId-Json) :-
    c34gl_engine:available_events(State, FormId, AvailEvents),
    reverse(FS.history, HistChron),
    maplist(atom_string, AvailEvents, AvailStrs),
    maplist(atom_string, HistChron, HistStrs),
    Json = _{
        formId: FormId,
        spid: FS.spid,
        win: FS.win,
        locals: FS.locals,
        lastTx: FS.last_tx,
        history: HistStrs,
        availableEvents: AvailStrs
    }.

tables_to_json(State, TablesJson) :-
    ( materialize_table(State, counter, Rows)
    -> TablesJson = _{counter: Rows}
    ; TablesJson = _{counter: []}
    ).


%% =============================================================================
%% Auto-start
%% =============================================================================

%% To start: swipl -g "start_server(8183), sleep(3600)" session_server.pl
