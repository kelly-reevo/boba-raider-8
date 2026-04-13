-module(todo_store_ffi).
-export([get_store/0, set_store/1, clear_store/0]).

%% Simple global storage using application environment
%% This maintains a single store reference across the Erlang VM

get_store() ->
    case application:get_env(todo_store, store_ref) of
        {ok, Store} -> {ok, Store};
        undefined -> {error, nil}
    end.

set_store(Store) ->
    application:set_env(todo_store, store_ref, Store),
    nil.

clear_store() ->
    application:unset_env(todo_store, store_ref),
    nil.
