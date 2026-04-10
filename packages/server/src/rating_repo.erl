-module(rating_repo).
-export([get_average_rating/1]).

%% FFI stub for unit-15 dependency: Get average rating for a store
%% Returns {ok, Rating} or {error, not_found}
get_average_rating(_StoreId) ->
    %% Stub: Dependencies from unit-15 will provide actual implementation
    %% Returns none when no ratings exist
    none.
