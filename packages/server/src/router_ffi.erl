-module(router_ffi).
-export([get_store_holder/0, set_store_holder/1, unsafe_cast/1]).

% Process dictionary key for the store holder actor
-define(STORE_HOLDER_KEY, store_holder_actor).

% Get the store holder actor reference, or start a new one if not exists
get_store_holder() ->
    case erlang:get(?STORE_HOLDER_KEY) of
        undefined ->
            % Will be initialized separately
            {error, nil};
        Pid ->
            {ok, Pid}
    end.

% Store the store holder actor reference
set_store_holder(Pid) ->
    erlang:put(?STORE_HOLDER_KEY, Pid),
    nil.

% Unsafe identity cast - at runtime Gleam types have the same representation
unsafe_cast(X) -> X.
