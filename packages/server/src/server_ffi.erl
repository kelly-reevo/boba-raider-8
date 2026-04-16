-module(server_ffi).

-export([read_body_string/1]).

% Read the request body and convert to string
% This handles both wisp's simulated connections and real connections
read_body_string(Req) ->
    try
        % Get the body from the request - in wisp it's the 'body' field
        Body = maps:get(body, Req, <<>>),
        read_body_content(Body)
    catch
        _:_ -> "{}"
    end.

% Read body content - handles different formats
read_body_content(Body) when is_binary(Body) ->
    case Body of
        <<>> -> "{}";
        Bin -> binary_to_list(Bin)
    end;
% Handle wisp's internal connection format (tuple with read function)
read_body_content({internal, _, ReadFun, _, _} = _Connection) when is_function(ReadFun) ->
    % Read from the connection using the read function
    try
        case ReadFun(999999) of  % Large size to read all at once
            {ok, Data} ->
                case Data of
                    <<>> -> "{}";
                    Bin when is_binary(Bin) -> binary_to_list(Bin);
                    _ -> "{}"
                end;
            _ -> "{}"
        end
    catch
        _:_ -> "{}"
    end;
% Handle wisp's connection tuple format
read_body_content({_Mod, _State, _ReadFun, _, _} = Connection) when is_tuple(Connection) ->
    % Try to extract body from connection state
    try
        case Connection of
            {internal, <<Body/binary>>, _, _, _} when is_binary(Body) ->
                case Body of
                    <<>> -> "{}";
                    Bin -> binary_to_list(Bin)
                end;
            {internal, BodyData, ReadFun, _, _} when is_function(ReadFun) ->
                % Try reading using the read function
                case ReadFun(999999) of
                    {ok, <<Body/binary>>} when is_binary(Body) ->
                        case Body of
                            <<>> -> "{}";
                            Bin -> binary_to_list(Bin)
                        end;
                    _ ->
                        % Try the body data directly
                        case BodyData of
                            <<Body/binary>> when is_binary(Body), Body =/= <<>> ->
                                binary_to_list(Body);
                            _ -> "{}"
                        end
                end;
            _ -> "{}"
        end
    catch
        _:_ -> "{}"
    end;
% Handle any other format
read_body_content(_Body) ->
    "{}".
