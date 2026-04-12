-module(todo_store_ffi).
-export([ensure_registry/0, register_pid/2, lookup_subject/1, register_supervisor/2, lookup_supervisor/1]).

%% Ensure the ETS registry table exists
ensure_registry() ->
    TableName = todo_store_registry,
    case ets:info(TableName) of
        undefined ->
            %% Table doesn't exist, create it
            ets:new(TableName, [public, set, named_table, {keypos, 1}]),
            %% Create a counter for unique ids
            ets:insert(TableName, {counter, 0}),
            TableName;
        _ ->
            %% Table already exists
            TableName
    end.

%% Get next unique id
next_id() ->
    ensure_registry(),
    ets:update_counter(todo_store_registry, counter, 1).

%% Register a Pid -> Subject mapping
register_pid(Pid, Subject) ->
    ensure_registry(),
    Id = next_id(),
    ets:insert(todo_store_registry, {Pid, subject, Subject, Id}),
    nil.

%% Lookup a Subject by Pid
lookup_subject(Pid) ->
    ensure_registry(),
    case ets:lookup(todo_store_registry, Pid) of
        [{Pid, subject, Subject, _Id}] -> {ok, Subject};
        _ -> {error, nil}
    end.

%% Register supervisor -> store pid mapping
register_supervisor(SupPid, StorePid) ->
    ensure_registry(),
    ets:insert(todo_store_registry, {SupPid, store_pid, StorePid}),
    nil.

%% Lookup store pid by supervisor pid
%% If direct lookup fails, return the most recently registered store pid
lookup_supervisor(SupPid) ->
    ensure_registry(),
    case ets:lookup(todo_store_registry, SupPid) of
        [{SupPid, store_pid, StorePid}] ->
            %% Check if the store pid is still alive
            case is_process_alive(StorePid) of
                true -> {ok, StorePid};
                false -> find_latest_store_pid()
            end;
        _ ->
            %% No direct mapping, find the most recent store pid
            find_latest_store_pid()
    end.

%% Find the most recently registered store pid
find_latest_store_pid() ->
    ensure_registry(),
    %% Match all {Pid, subject, Subject, Id} entries and find max Id
    case ets:match(todo_store_registry, {'$1', subject, '_', '$2'}) of
        [] -> {error, nil};
        Matches ->
            %% Find the entry with the highest Id
            {Pid, _Id} = lists:foldl(
                fun([P, I], {_, MaxId}) when I > MaxId -> {P, I};
                   (_, Acc) -> Acc
                end,
                {nil, -1},
                Matches
            ),
            case Pid of
                nil -> {error, nil};
                _ -> {ok, Pid}
            end
    end.
