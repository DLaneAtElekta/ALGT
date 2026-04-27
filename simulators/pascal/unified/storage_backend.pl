% storage_backend.pl — SQL transaction-log emitting storage backend.
%
% Every TDataSet / TSQLQuery operation produces one entry in the logical
% transaction log. The log entries — not any individual TDataSet — are the
% canonical event stream that interleaves across forms.
%
% Log entry shape:
%   log(Seq, Form, Action, Target, Payload)
%     Seq     = monotonic counter
%     Form    = current form name (or '' if global)
%     Action  = open | close | insert | edit | post | delete | apply_updates
%             | start_tx | commit | rollback
%             | set_field | exec_sql
%     Target  = dataset/table/query name
%     Payload = list of name=value pairs

:- module(storage_backend, [
    sql_open/4,
    sql_close/3,
    sql_insert/3,
    sql_edit/3,
    sql_set_field/5,
    sql_post/3,
    sql_delete/3,
    sql_apply_updates/3,
    sql_start_tx/3,
    sql_commit/3,
    sql_rollback/3,
    sql_exec_sql/4,
    log_entries/2
]).

:- use_module(simulator_state, [
    append_log/3,
    log_entries/2
]).

next_seq(S0, Seq, S) :-
    ( get_dict(seq, S0, N) -> N1 is N + 1 ; N1 = 1 ),
    Seq = N1,
    S = S0.put(seq, N1).

current_form(S, Form) :-
    ( get_dict(current_form, S, F), F \== none -> Form = F ; Form = '' ).

emit(Action, Target, Payload, S0, S) :-
    next_seq(S0, Seq, S1),
    current_form(S1, Form),
    append_log(log(Seq, Form, Action, Target, Payload), S1, S).

sql_open(Name, Sql, S0, S)         :- emit(open, Name, [sql=Sql], S0, S).
sql_close(Name, S0, S)             :- emit(close, Name, [], S0, S).
sql_insert(Name, S0, S)            :- emit(insert, Name, [], S0, S).
sql_edit(Name, S0, S)              :- emit(edit, Name, [], S0, S).
sql_set_field(Name, Field, Val, S0, S) :-
    emit(set_field, Name, [field=Field, value=Val], S0, S).
sql_post(Name, S0, S)              :- emit(post, Name, [], S0, S).
sql_delete(Name, S0, S)            :- emit(delete, Name, [], S0, S).
sql_apply_updates(Name, S0, S)     :- emit(apply_updates, Name, [], S0, S).
sql_start_tx(Name, S0, S)          :- emit(start_tx, Name, [], S0, S).
sql_commit(Name, S0, S)            :- emit(commit, Name, [], S0, S).
sql_rollback(Name, S0, S)          :- emit(rollback, Name, [], S0, S).
sql_exec_sql(Name, Sql, S0, S)     :- emit(exec_sql, Name, [sql=Sql], S0, S).
