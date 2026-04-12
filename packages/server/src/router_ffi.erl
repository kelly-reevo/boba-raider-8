-module(router_ffi).
-export([configure/1, get_store/0, execute_with_catch/1]).

% ETS table name for storing the router configuration
-define(ROUTER_TABLE, router_config).
-define(STORE_KEY, store).

%% Initialize or update the store configuration
configure(Store) ->
    % Create ETS table if it doesn't exist
    case ets:info(?ROUTER_TABLE) of
        undefined ->
            ets:new(?ROUTER_TABLE, [named_table, public, {read_concurrency, true}]);
        _ ->
            ok
    end,
    % Insert the store
    ets:insert(?ROUTER_TABLE, {?STORE_KEY, Store}),
    nil.

%% Get the current store configuration
get_store() ->
    case ets:info(?ROUTER_TABLE) of
        undefined ->
            {none, nil};
        _ ->
            case ets:lookup(?ROUTER_TABLE, ?STORE_KEY) of
                [{?STORE_KEY, Store}] ->
                    {some, Store};
                [] ->
                    {none, nil}
            end
    end.

%% Execute a handler function with error catching
%% Returns {ok, Response} on success, {error, nil} on any exception
%% This prevents stack traces from leaking to the client
execute_with_catch(Handler) ->
    try
        Response = Handler(),
        {ok, Response}
    catch
        _:_ ->
            %% Catch any exception (throw, error, exit) and return safe error
            %% Do not leak stack traces or internal details
            {error, nil}
    end.
