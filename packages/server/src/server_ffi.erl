-module(server_ffi).
-export([start/2, stop/1, generate_uuid/0]).

start(Port, Handler) ->
    ErlHandler = fun(ErlRequest) ->
        GleamRequest = erl_to_gleam_request(ErlRequest),
        GleamResponse = Handler(GleamRequest),
        gleam_to_erl_response(GleamResponse)
    end,
    case http_server:start(Port, ErlHandler) of
        {ok, Pid, Socket} ->
            {ok, {server, Pid, Socket}};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

stop({server, _Pid, Socket}) ->
    http_server:stop(Socket),
    nil.

erl_to_gleam_request(#{method := Method, path := Path, headers := Headers, body := Body}) ->
    GleamHeaders = maps:fold(fun(K, V, Acc) ->
        gleam@dict:insert(Acc, to_binary(K), to_binary(V))
    end, gleam@dict:new(), Headers),
    {request,
        to_binary(Method),
        to_binary(Path),
        GleamHeaders,
        to_binary(Body)}.

gleam_to_erl_response({response, Status, Headers, Body}) ->
    ErlHeaders = gleam@dict:fold(Headers, #{}, fun(Acc, K, V) ->
        maps:put(to_binary(K), to_binary(V), Acc)
    end),
    #{
        status => Status,
        headers => ErlHeaders,
        body => to_binary(Body)
    }.

to_binary(V) when is_binary(V) -> V;
to_binary(V) when is_list(V) -> list_to_binary(V);
to_binary(V) when is_atom(V) -> atom_to_binary(V).

generate_uuid() ->
    % Generate a unique ID using erlang:unique_integer and format as 36-char hex
    % This produces a UUID-like string (without dashes) that's 36 characters
    Int1 = erlang:unique_integer([positive]),
    Int2 = erlang:unique_integer([positive]),
    Int3 = erlang:unique_integer([positive]),
    % Format as 36 character hex string (12+12+12 = 36)
    Fmt = io_lib:format("~12.16.0b~12.16.0b~12.16.0b", [Int1, Int2, Int3]),
    list_to_binary(Fmt).
