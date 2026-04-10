-module(ratings_store_ffi).
-export([init_table/0, from_record/1, make_record/4, make_drink_pattern/1,
         make_user_pattern/1, unique_id/0]).

%% Initialize the ETS table with options: public, set, named_table
init_table() ->
    ets:new(ratings, [public, set, named_table]).

%% Convert ETS tuple record to Gleam Rating type
%% Record format: {RatingId, UserId, DrinkId, Value} as binaries
from_record({RatingIdBin, UserIdBin, DrinkIdBin, Value}) ->
    {rating,
     {rating_id, RatingIdBin},
     {user_id, UserIdBin},
     {drink_id, DrinkIdBin},
     Value}.

%% Create a record tuple for ETS insertion
make_record(Id, User, Drink, Value) ->
    {Id, User, Drink, Value}.

%% Create match pattern for drink lookups: {'_', '_', DrinkId, '_'}
make_drink_pattern(DrinkId) ->
    {'_', '_', DrinkId, '_'}.

%% Create match pattern for user lookups: {'_', UserId, '_', '_'}
make_user_pattern(UserId) ->
    {'_', UserId, '_', '_'}.

%% Generate unique ID string
unique_id() ->
    iolist_to_binary(integer_to_list(erlang:unique_integer([positive]), 36)).
