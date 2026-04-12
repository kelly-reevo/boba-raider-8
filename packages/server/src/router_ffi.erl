-module(router_ffi).
-export([get_store_holder/0, set_store_holder/1, unsafe_cast/1]).

% Registered name for the store holder actor
-define(STORE_HOLDER_NAME, store_holder_actor).

% Get the store holder actor reference by registered name
get_store_holder() ->
    case whereis(?STORE_HOLDER_NAME) of
        undefined ->
            {error, nil};
        Pid ->
            {ok, Pid}
    end.

% Register the store holder actor with a global name
set_store_holder(Pid) ->
    try
        register(?STORE_HOLDER_NAME, Pid)
    catch
        error:badarg ->
            % Already registered, that's fine
            ok
    end,
    nil.

% Unsafe identity cast - at runtime Gleam types have the same representation
unsafe_cast(X) -> X.
