-module(router_ffi).
-export([configure/1, get_store/0]).

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
