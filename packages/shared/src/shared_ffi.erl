-module(shared_ffi).
-export([system_time/1, int_to_string/1]).

system_time(Unit) ->
    erlang:system_time(Unit).

int_to_string(N) ->
    integer_to_binary(N).
