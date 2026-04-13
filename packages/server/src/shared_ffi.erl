-module(shared_ffi).
-export([current_timestamp/0]).

%% Return current UTC timestamp in ISO8601 format
current_timestamp() ->
    {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time(),
    lists:flatten(
        io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ",
                      [Year, Month, Day, Hour, Minute, Second])
    ).
