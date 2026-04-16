-module(server_ffi).

-export([read_body_string/1]).

% Read the request body and convert to string
read_body_string(Req) ->
    % In wisp, the body is in the request and can be read
    % We need to access the underlying body
    try
        Body = maps:get(body, Req, <<>>),
        case Body of
            <<>> -> "{}";
            Bin when is_binary(Bin) -> binary_to_list(Bin);
            _ -> "{}"
        end
    catch
        _:_ -> "{}"
    end.
