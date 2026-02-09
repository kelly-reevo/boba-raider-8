-module(http_server).
-export([start/2, stop/1]).

start(Port, Handler) ->
    {ok, Socket} = gen_tcp:listen(Port, [
        binary,
        {active, false},
        {reuseaddr, true},
        {packet, http_bin}
    ]),
    Pid = spawn(fun() -> accept_loop(Socket, Handler) end),
    {ok, Pid, Socket}.

stop(Socket) ->
    gen_tcp:close(Socket).

accept_loop(Socket, Handler) ->
    case gen_tcp:accept(Socket) of
        {ok, Client} ->
            spawn(fun() -> handle_client(Client, Handler) end),
            accept_loop(Socket, Handler);
        {error, closed} ->
            ok
    end.

handle_client(Socket, Handler) ->
    case read_request(Socket, #{}) of
        {ok, Request} ->
            Response = Handler(Request),
            send_response(Socket, Response);
        {error, _} ->
            ok
    end,
    gen_tcp:close(Socket).

read_request(Socket, Acc) ->
    inet:setopts(Socket, [{packet, http_bin}]),
    case gen_tcp:recv(Socket, 0, 30000) of
        {ok, {http_request, Method, {abs_path, Path}, _}} ->
            read_request(Socket, Acc#{method => Method, path => Path});
        {ok, {http_header, _, Key, _, Value}} ->
            Headers = maps:get(headers, Acc, #{}),
            read_request(Socket, Acc#{headers => Headers#{Key => Value}});
        {ok, http_eoh} ->
            Headers = maps:get(headers, Acc, #{}),
            ContentLength = case maps:get('Content-Length', Headers, undefined) of
                undefined -> 0;
                Len -> binary_to_integer(Len)
            end,
            inet:setopts(Socket, [{packet, raw}]),
            Body = case ContentLength > 0 of
                true ->
                    {ok, B} = gen_tcp:recv(Socket, ContentLength, 30000),
                    B;
                false ->
                    <<>>
            end,
            {ok, Acc#{body => Body, headers => Headers}};
        {error, Reason} ->
            {error, Reason}
    end.

send_response(Socket, #{status := Status, headers := Headers, body := Body}) ->
    StatusLine = io_lib:format("HTTP/1.1 ~p ~s\r\n", [Status, status_text(Status)]),
    HeaderLines = maps:fold(fun(K, V, Acc) ->
        [io_lib:format("~s: ~s\r\n", [K, V]) | Acc]
    end, [], Headers),
    ContentLength = io_lib:format("Content-Length: ~p\r\n", [byte_size(Body)]),
    Response = [StatusLine, HeaderLines, ContentLength, "\r\n", Body],
    gen_tcp:send(Socket, Response).

status_text(200) -> "OK";
status_text(201) -> "Created";
status_text(204) -> "No Content";
status_text(400) -> "Bad Request";
status_text(404) -> "Not Found";
status_text(500) -> "Internal Server Error";
status_text(_) -> "Unknown".
