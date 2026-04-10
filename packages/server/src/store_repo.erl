-module(store_repo).
-export([get_store_by_id/1, count_drinks/1]).

%% FFI stub for unit-4 dependency: Get store by ID
%% Returns {ok, Store} or {error, not_found}
get_store_by_id(_Id) ->
    %% Stub: Dependencies from unit-4 will provide actual implementation
    %% Returning none for now - unit-4 will replace this
    none.

%% FFI stub for unit-4 dependency: Count drinks for a store
count_drinks(_StoreId) ->
    %% Stub: Dependencies from unit-4 will provide actual implementation
    0.
