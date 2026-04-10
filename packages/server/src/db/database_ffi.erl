-module(database_ffi).
-export([connect/1, disconnect/1, execute/3]).

connect(Url) ->
    case epgsql:connect(Url) of
        {ok, Conn} -> {ok, Conn};
        {error, Reason} -> {error, lists:flatten(io_lib:format("~p", [Reason]))}
    end.

disconnect(Conn) ->
    epgsql:close(Conn),
    ok.

execute(Conn, Sql, _Params) ->
    case epgsql:squery(Conn, Sql) of
        {ok, _Columns, Rows} ->
            {ok, rows_to_strings(Rows)};
        {ok, Count} ->
            {ok, [[integer_to_list(Count)]]};
        {error, Reason} ->
            {error, lists:flatten(io_lib:format("~p", [Reason]))}
    end.

rows_to_strings(Rows) ->
    lists:map(fun(Row) ->
        tuple_to_strings(Row)
    end, Rows).

tuple_to_strings(Tuple) ->
    lists:map(fun(Elem) ->
        case Elem of
            null -> "null";
            Bin when is_binary(Bin) -> binary_to_list(Bin);
            Int when is_integer(Int) -> integer_to_list(Int);
            Float when is_float(Float) -> lists:flatten(io_lib:format("~f", [Float]));
            List when is_list(List) -> List;
            _ -> lists:flatten(io_lib:format("~p", [Elem]))
        end
    end, tuple_to_list(Tuple)).
