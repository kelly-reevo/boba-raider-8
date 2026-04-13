import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/string

// Dependencies (to be provided)
import drink_store.{type DrinkStore}

/// Input for creating a new rating
pub type CreateRatingInput {
  CreateRatingInput(
    drink_id: String,
    reviewer_name: Option(String),
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    review_text: Option(String),
  )
}

/// Rating record matching boundary contract output
pub type RatingRecord {
  RatingRecord(
    id: String,
    drink_id: String,
    reviewer_name: Option(String),
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    review_text: Option(String),
    created_at: Int,
  )
}

/// Aggregated rating summary for a drink
pub type RatingAggregate {
  RatingAggregate(
    drink_id: String,
    average_overall: Float,
    average_sweetness: Float,
    average_boba_texture: Float,
    average_tea_strength: Float,
    total_reviews: Int,
  )
}

/// Actor message types
pub type RatingServiceMsg {
  CreateRating(CreateRatingInput, Subject(Result(RatingRecord, String)))
  GetRatingById(String, Subject(Result(RatingRecord, String)))
  ListRatingsByDrink(String, Subject(List(RatingRecord)))
  GetRatingAggregate(String, Subject(Result(RatingAggregate, String)))
  DeleteRating(String, Subject(Result(Bool, String)))
}

pub type RatingService =
  Subject(RatingServiceMsg)

/// Service state tracking ratings and aggregates
pub opaque type ServiceState {
  ServiceState(
    ratings: Dict(String, RatingRecord),
    aggregates: Dict(String, RatingAggregate),
    drink_store: DrinkStore,
    next_id: Int,
  )
}

// FFI for generating UUID
@external(erlang, "erlang", "unique_integer")
fn unique_integer() -> Int

@external(erlang, "erlang", "phash2")
fn phash2(term: any, range: Int) -> Int

fn generate_uuid() -> String {
  let timestamp = system_time_milliseconds()
  let unique = unique_integer()
  let hash = phash2(unique, 16_777_215)
  format_uuid(timestamp, hash)
}

fn format_uuid(timestamp: Int, hash: Int) -> String {
  let hex1 = int_to_hex_string(timestamp % 4_294_967_296)
  let hex2 = int_to_hex_string(hash % 65_536)
  let hex3 = int_to_hex_string({ hash / 65_536 } % 65_536)
  let hex4 = int_to_hex_string(unique_integer() % 65_536)
  let hex5 = int_to_hex_string(system_time_milliseconds() % 4_294_967_296)

  pad_left(hex1, 8) <> "-" <> pad_left(hex2, 4) <> "-" <> pad_left(hex3, 4) <> "-" <> pad_left(hex4, 4) <> "-" <> pad_left(hex5, 12)
}

fn pad_left(s: String, len: Int) -> String {
  case string.length(s) {
    n if n >= len -> s
    n -> string.repeat("0", len - n) <> s
  }
}

fn int_to_hex_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_hex_string(n, "")
  }
}

fn do_int_to_hex_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = n % 16
      let char = case digit {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        9 -> "9"
        10 -> "a"
        11 -> "b"
        12 -> "c"
        13 -> "d"
        14 -> "e"
        _ -> "f"
      }
      do_int_to_hex_string(n / 16, char <> acc)
    }
  }
}

// FFI for system time in milliseconds
@external(erlang, "erlang", "system_time")
fn erlang_system_time(unit: Int) -> Int

fn system_time_milliseconds() -> Int {
  erlang_system_time(1000)
}

// Validation functions
fn validate_create_input(input: CreateRatingInput) -> Result(Nil, String) {
  // Validate drink_id is non-empty
  case string.length(string.trim(input.drink_id)) > 0 {
    False -> Error("drink_id is required")
    True -> {
      // Validate overall_rating is between 1.0 and 5.0
      case input.overall_rating >=. 1.0 && input.overall_rating <=. 5.0 {
        False -> Error("overall_rating must be between 1 and 5")
        True -> {
          // Validate sweetness is between 1.0 and 5.0
          case input.sweetness >=. 1.0 && input.sweetness <=. 5.0 {
            False -> Error("sweetness must be between 1 and 5")
            True -> {
              // Validate boba_texture is between 1.0 and 5.0
              case input.boba_texture >=. 1.0 && input.boba_texture <=. 5.0 {
                False -> Error("boba_texture must be between 1 and 5")
                True -> {
                  // Validate tea_strength is between 1.0 and 5.0
                  case input.tea_strength >=. 1.0 && input.tea_strength <=. 5.0 {
                    False -> Error("tea_strength must be between 1 and 5")
                    True -> Ok(Nil)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

fn validate_uuid(id: String) -> Bool {
  string.length(id) > 0 && string.contains(id, "-")
}

// Aggregate calculation: recalculate all aggregates for a drink
fn recalculate_aggregate(
  state: ServiceState,
  drink_id: String,
) -> RatingAggregate {
  let drink_ratings =
    state.ratings
    |> dict.values()
    |> list.filter(fn(r) { r.drink_id == drink_id })

  let total = list.length(drink_ratings)

  case total {
    0 -> RatingAggregate(
      drink_id: drink_id,
      average_overall: 0.0,
      average_sweetness: 0.0,
      average_boba_texture: 0.0,
      average_tea_strength: 0.0,
      total_reviews: 0,
    )
    _ -> {
      let sum_overall = list.fold(drink_ratings, 0.0, fn(acc, r) { acc +. r.overall_rating })
      let sum_sweetness = list.fold(drink_ratings, 0.0, fn(acc, r) { acc +. r.sweetness })
      let sum_boba = list.fold(drink_ratings, 0.0, fn(acc, r) { acc +. r.boba_texture })
      let sum_tea = list.fold(drink_ratings, 0.0, fn(acc, r) { acc +. r.tea_strength })

      let total_float = int.to_float(total)

      RatingAggregate(
        drink_id: drink_id,
        average_overall: sum_overall /. total_float,
        average_sweetness: sum_sweetness /. total_float,
        average_boba_texture: sum_boba /. total_float,
        average_tea_strength: sum_tea /. total_float,
        total_reviews: total,
      )
    }
  }
}

// Actor implementation
fn handle_message(state: ServiceState, msg: RatingServiceMsg) -> actor.Next(ServiceState, RatingServiceMsg) {
  case msg {
    CreateRating(input, reply_to) -> {
      case validate_create_input(input) {
        Error(err) -> {
          actor.send(reply_to, Error(err))
          actor.continue(state)
        }
        Ok(_) -> {
          // Verify drink exists using drink_service dependency
          case drink_store.get_drink_by_id(state.drink_store, input.drink_id) {
            Error(_) -> {
              actor.send(reply_to, Error("Drink not found"))
              actor.continue(state)
            }
            Ok(_) -> {
              let now = system_time_milliseconds()
              let id = generate_uuid()
              let record = RatingRecord(
                id: id,
                drink_id: input.drink_id,
                reviewer_name: input.reviewer_name,
                overall_rating: input.overall_rating,
                sweetness: input.sweetness,
                boba_texture: input.boba_texture,
                tea_strength: input.tea_strength,
                review_text: input.review_text,
                created_at: now,
              )

              // Store the rating
              let new_ratings = dict.insert(state.ratings, id, record)

              // Recalculate aggregate for this drink
              let new_aggregate = recalculate_aggregate(ServiceState(..state, ratings: new_ratings), input.drink_id)
              let new_aggregates = dict.insert(state.aggregates, input.drink_id, new_aggregate)

              let new_state = ServiceState(
                ..state,
                ratings: new_ratings,
                aggregates: new_aggregates,
              )

              actor.send(reply_to, Ok(record))
              actor.continue(new_state)
            }
          }
        }
      }
    }

    GetRatingById(id, reply_to) -> {
      case validate_uuid(id) {
        False -> {
          actor.send(reply_to, Error("Invalid UUID format"))
          actor.continue(state)
        }
        True -> {
          case dict.get(state.ratings, id) {
            Ok(record) -> {
              actor.send(reply_to, Ok(record))
              actor.continue(state)
            }
            Error(_) -> {
              actor.send(reply_to, Error("Rating not found"))
              actor.continue(state)
            }
          }
        }
      }
    }

    ListRatingsByDrink(drink_id, reply_to) -> {
      let ratings =
        state.ratings
        |> dict.values()
        |> list.filter(fn(r) { r.drink_id == drink_id })
      actor.send(reply_to, ratings)
      actor.continue(state)
    }

    GetRatingAggregate(drink_id, reply_to) -> {
      case dict.get(state.aggregates, drink_id) {
        Ok(aggregate) -> {
          actor.send(reply_to, Ok(aggregate))
          actor.continue(state)
        }
        Error(_) -> {
          // Return empty aggregate if none exists
          let empty = RatingAggregate(
            drink_id: drink_id,
            average_overall: 0.0,
            average_sweetness: 0.0,
            average_boba_texture: 0.0,
            average_tea_strength: 0.0,
            total_reviews: 0,
          )
          actor.send(reply_to, Ok(empty))
          actor.continue(state)
        }
      }
    }

    DeleteRating(id, reply_to) -> {
      case dict.get(state.ratings, id) {
        Ok(rating) -> {
          let drink_id = rating.drink_id
          let new_ratings = dict.delete(state.ratings, id)

          // Recalculate aggregate after deletion
          let new_aggregate = recalculate_aggregate(ServiceState(..state, ratings: new_ratings), drink_id)
          let new_aggregates = dict.insert(state.aggregates, drink_id, new_aggregate)

          let new_state = ServiceState(
            ..state,
            ratings: new_ratings,
            aggregates: new_aggregates,
          )

          actor.send(reply_to, Ok(True))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Rating not found"))
          actor.continue(state)
        }
      }
    }
  }
}

// Public API

pub fn start(drink_store: DrinkStore) -> Result(RatingService, String) {
  let initial_state = ServiceState(
    ratings: dict.new(),
    aggregates: dict.new(),
    drink_store: drink_store,
    next_id: 1,
  )

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start rating service actor")
  }
}

pub fn create_rating(service: RatingService, input: CreateRatingInput) -> Result(RatingRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(service, CreateRating(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for rating service")
  }
}

pub fn get_rating_by_id(service: RatingService, id: String) -> Result(RatingRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(service, GetRatingById(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for rating service")
  }
}

pub fn list_ratings_by_drink(service: RatingService, drink_id: String) -> List(RatingRecord) {
  let reply_subject = process.new_subject()
  actor.send(service, ListRatingsByDrink(drink_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(ratings) -> ratings
    Error(_) -> []
  }
}

pub fn get_rating_aggregate(service: RatingService, drink_id: String) -> Result(RatingAggregate, String) {
  let reply_subject = process.new_subject()
  actor.send(service, GetRatingAggregate(drink_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for rating service")
  }
}

pub fn delete_rating(service: RatingService, id: String) -> Result(Bool, String) {
  let reply_subject = process.new_subject()
  actor.send(service, DeleteRating(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for rating service")
  }
}
