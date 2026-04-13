%% FFI module for todo_actor - UUID generation and datetime functions
-module(todo_actor_ffi).
-export([generate_uuid/0, current_datetime/0]).

%% @doc Generate a UUID v4 string (random-based)
%% Returns a standard UUID string like "550e8400-e29b-41d4-a716-446655440000"
-spec generate_uuid() -> binary().
generate_uuid() ->
    <<A:32, B:16, C:16, D:16, E:48>> = crypto:strong_rand_bytes(16),
    %% UUID v4 variant: version bits (0010) in top 4 bits of C, variant bits (10) in top 2 bits of D
    C1 = (C band 16#0FFF) bor 16#4000,  % Version 4
    D1 = (D band 16#3FFF) bor 16#8000,  % Variant 10
    UUIDBin = io_lib:format(
        "~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b",
        [A, B, C1, D1, E]
    ),
    list_to_binary(UUIDBin).

%% @doc Get current datetime in ISO8601 format
%% Returns a string like "2024-01-15T10:30:00Z"
-spec current_datetime() -> binary().
current_datetime() ->
    {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time(),
    DateBin = io_lib:format(
        "~4.10.0b-~2.10.0b-~2.10.0bT~2.10.0b:~2.10.0b:~2.10.0bZ",
        [Year, Month, Day, Hour, Minute, Second]
    ),
    list_to_binary(DateBin).
