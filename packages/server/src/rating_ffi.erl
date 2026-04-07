-module(rating_ffi).
-export([generate_id/0]).

generate_id() ->
    Bytes = crypto:strong_rand_bytes(16),
    Hex = binary:encode_hex(Bytes),
    string:lowercase(Hex).
