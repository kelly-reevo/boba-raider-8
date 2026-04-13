-module(server_ffi).
-export([start/2, stop/1]).

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

erl_to_gleam_request(#{method := Method, path := Path, headers := Headers, body := Body} = Request) ->
    GleamHeaders = maps:fold(fun(K, V, Acc) ->
        gleam@dict:insert(Acc, to_binary(K), to_binary(V))
    end, gleam@dict:new(), Headers),
    Query = maps:get(query, Request, undefined),
    GleamQuery = case Query of
        undefined -> none;
        <<>> -> none;
        Q -> {some, to_binary(Q)}
    end,
    {request,
        to_binary(Method),
        to_binary(Path),
        GleamQuery,
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
