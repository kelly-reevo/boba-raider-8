/// Simple in-memory ratings storage using ETS table
/// Simplicity bias: Single ETS table with simple operations

import gleam/list
import gleam/option.{type Option, None, Some}
import shared.{type DrinkId, type Rating, type RatingId, type UserId}

// ETS table reference type
pub type RatingsTable

/// Initialize the ratings store (creates ETS table via FFI)
@external(erlang, "ratings_store_ffi", "init_table")
pub fn init() -> RatingsTable

/// Insert a record into the table
@external(erlang, "ets", "insert")
fn ets_insert(table: RatingsTable, record: any) -> any

/// Lookup a record by key (returns list of records)
@external(erlang, "ets", "lookup")
fn ets_lookup(table: RatingsTable, key: any) -> List(any)

/// Delete a record by key
@external(erlang, "ets", "delete")
fn ets_delete(table: RatingsTable, key: any) -> any

/// Match all records
@external(erlang, "ets", "match_object")
fn ets_match_object(table: RatingsTable, pattern: any) -> List(any)

// FFI helpers for tuple/pattern construction
@external(erlang, "ratings_store_ffi", "make_record")
fn make_record(id: String, user: String, drink: String, value: Int) -> any

@external(erlang, "ratings_store_ffi", "make_drink_pattern")
fn make_drink_pattern(drink_id: String) -> any

@external(erlang, "ratings_store_ffi", "make_user_pattern")
fn make_user_pattern(user_id: String) -> any

@external(erlang, "ratings_store_ffi", "unique_id")
fn unique_id_ffi() -> String

/// Storage record: {rating_id, user_id, drink_id, value}
fn to_record(rating: Rating) -> any {
  let id_str = shared.rating_id_to_string(rating.id)
  let user_str = shared.user_id_to_string(rating.user_id)
  let drink_str = shared.drink_id_to_string(rating.drink_id)
  make_record(id_str, user_str, drink_str, rating.value)
}

fn from_record(record: any) -> Rating {
  from_record_ffi(record)
}

@external(erlang, "ratings_store_ffi", "from_record")
fn from_record_ffi(record: any) -> Rating

/// Store a new rating
pub fn insert(table: RatingsTable, rating: Rating) -> Rating {
  ets_insert(table, to_record(rating))
  rating
}

/// Create and store a new rating with auto-generated ID
pub fn create_rating(
  table: RatingsTable,
  user_id: UserId,
  drink_id: DrinkId,
  value: Int,
) -> Rating {
  let rating = shared.Rating(
    id: shared.rating_id_from_string(unique_id_ffi()),
    user_id: user_id,
    drink_id: drink_id,
    value: value,
  )
  insert(table, rating)
  rating
}

/// Get a rating by ID
pub fn get_by_id(table: RatingsTable, rating_id: RatingId) -> Option(Rating) {
  let id_str = shared.rating_id_to_string(rating_id)
  let results = ets_lookup(table, id_str)
  case results {
    [] -> None
    [first, ..] -> Some(from_record(first))
  }
}

/// Delete a rating by ID. Returns True if deleted, False if not found.
pub fn delete(table: RatingsTable, rating_id: RatingId) -> Bool {
  let id_str = shared.rating_id_to_string(rating_id)
  let results = ets_lookup(table, id_str)
  case results {
    [] -> False
    _ -> {
      ets_delete(table, id_str)
      True
    }
  }
}

/// Get all ratings for a specific drink
pub fn get_by_drink(table: RatingsTable, drink_id: DrinkId) -> List(Rating) {
  let drink_str = shared.drink_id_to_string(drink_id)
  let pattern = make_drink_pattern(drink_str)
  let records = ets_match_object(table, pattern)
  list.map(records, from_record)
}

/// Get all ratings by a specific user
pub fn get_by_user(table: RatingsTable, user_id: UserId) -> List(Rating) {
  let user_str = shared.user_id_to_string(user_id)
  let pattern = make_user_pattern(user_str)
  let records = ets_match_object(table, pattern)
  list.map(records, from_record)
}

/// Calculate average rating for a drink
pub fn calculate_drink_average(table: RatingsTable, drink_id: DrinkId) -> Float {
  let ratings = get_by_drink(table, drink_id)
  case ratings {
    [] -> 0.0
    rs -> {
      let sum = list.fold(rs, 0, fn(acc, r) { acc + r.value })
      int_to_float(sum) /. int_to_float(list.length(rs))
    }
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
