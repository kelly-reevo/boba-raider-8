-module(jwt_ffi).
-export([hmac_sha256/2, system_time/0, binary_to_atom/1]).

%% HMAC-SHA256 signature
hmac_sha256(Data, Key) ->
    crypto:mac(hmac, sha256, Key, Data).

%% Current timestamp in seconds
system_time() ->
    erlang:system_time(second).

%% Convert binary to atom
binary_to_atom(Bin) ->
    binary_to_atom(Bin, utf8).
