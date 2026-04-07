-module(id_ffi).
-export([unique_id/0]).

unique_id() ->
    Int = erlang:unique_integer([positive, monotonic]),
    integer_to_binary(Int).
