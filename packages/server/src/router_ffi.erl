-module(router_ffi).
-export([execute_with_catch/1]).

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
