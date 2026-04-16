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
    % Generate a UUID with standard 8-4-4-4-12 format using unique integers
    Int1 = erlang:unique_integer([positive]),
    Int2 = erlang:unique_integer([positive]),
    Int3 = erlang:unique_integer([positive]),
    % Extract portions to create UUID format: 8-4-4-4-12 hex chars
    % Using bit manipulation to extract segments
    A = Int1 band 16#FFFFFFFF,           % 8 hex chars (32 bits)
    B = (Int1 bsr 32) band 16#FFFF,        % 4 hex chars (16 bits)
    C = ((Int1 bsr 48) band 16#0FFF) bor 16#4000,  % 4 hex with version 4
    D = Int2 band 16#3FFF bor 16#8000,     % 4 hex with variant 10
    E = ((Int2 bsr 16) band 16#FFFFFFFFFFFF) + (Int3 band 16#FF),  % 12 hex chars
    Fmt = io_lib:format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [A, B, C, D, E]),
    list_to_binary(Fmt).
