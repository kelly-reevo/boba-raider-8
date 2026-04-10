%% Erlang FFI module for rating handler
%% Handles JSON parsing for rating requests

-module(rating_handler_ffi).
-export([extract_int_field/2, extract_optional_string/2]).

%% Extract integer field from a map
extract_int_field(Map, Field) when is_map(Map) ->
    case maps:get(Field, Map, undefined) of
        undefined ->
            {error, <<"missing field">>};
        Value when is_integer(Value) ->
            {ok, Value};
        Value when is_float(Value) ->
            {ok, round(Value)};
        Value when is_binary(Value) ->
            try
                {ok, binary_to_integer(Value)}
            catch
                _:_ -> {error, <<"not a number">>}
            end;
        _ ->
            {error, <<"not a number">>}
    end;
extract_int_field(_, _) ->
    {error, <<"expected object">>}.

%% Extract optional string field from a map
extract_optional_string(Map, Field) when is_map(Map) ->
    case maps:get(Field, Map, undefined) of
        undefined ->
            {ok, none};
        null ->
            {ok, none};
        Value when is_binary(Value) ->
            case byte_size(Value) =< 1000 of
                true -> {ok, {some, Value}};
                false -> {error, <<"too long (max 1000 chars)">>}
            end;
        _ ->
            {error, <<"expected string or null">>}
    end;
extract_optional_string(_, _) ->
    {error, <<"expected object">>}.
