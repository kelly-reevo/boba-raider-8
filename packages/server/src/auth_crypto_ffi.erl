-module(auth_crypto_ffi).
-export([hash_password/2, generate_salt/0, hmac_sign/2, generate_id/0, system_time_seconds/0]).

hash_password(Password, Salt) ->
    Hash = crypto:hash(sha256, <<Salt/binary, Password/binary>>),
    base64:encode(Hash).

generate_salt() ->
    base64:encode(crypto:strong_rand_bytes(16)).

hmac_sign(Data, Secret) ->
    Mac = crypto:mac(hmac, sha256, Secret, Data),
    base64:encode(Mac).

generate_id() ->
    Bytes = crypto:strong_rand_bytes(16),
    Hex = lists:flatten([io_lib:format("~2.16.0b", [B]) || <<B>> <= Bytes]),
    list_to_binary(Hex).

system_time_seconds() ->
    erlang:system_time(second).
