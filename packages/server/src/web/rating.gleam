/// Rating module (unit-14)
/// Create/update store ratings with overall score (1-5) and optional text review
/// One rating per user per store (upsert on duplicate)

import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result
import shared.{type AppError, type Rating, type RatingWithUser, NotFound, InternalError}

import web/user.{type UserActor}

/// Rating actor message types
pub type RatingMsg {
  CreateRating(
    store_id: String,
    user_id: String,
    overall_score: Int,
    review_text: Option(String),
    reply: process.Subject(Result(Rating, AppError)),
  )
  GetRatingForUserAndStore(
    store_id: String,
    user_id: String,
    reply: process.Subject(Result(Rating, AppError)),
  )
  GetRatingsForStore(
    store_id: String,
    reply: process.Subject(List(Rating)),
  )
  Shutdown
}

pub type RatingActor =
  process.Subject(RatingMsg)

/// Composite key for user+store uniqueness
fn make_key(store_id: String, user_id: String) -> String {
  store_id <> ":" <> user_id
}

/// In-memory state for ratings
pub type RatingState {
  RatingState(
    ratings: Dict(String, Rating),  // keyed by rating id
    user_store_index: Dict(String, String),  // keyed by store_id:user_id, value is rating id
    next_id: Int,
  )
}

fn initial_state() -> RatingState {
  RatingState(
    ratings: dict.new(),
    user_store_index: dict.new(),
    next_id: 1,
  )
}

/// Generate current timestamp
fn now() -> String {
  // In production, use actual timestamp
  "2024-01-01T00:00:00Z"
}

/// Start the rating actor
pub fn start() -> Result(RatingActor, String) {
  let handler = fn(state: RatingState, msg: RatingMsg) {
    case msg {
      CreateRating(store_id, user_id, overall_score, review_text, reply) -> {
        let key = make_key(store_id, user_id)
        let current_time = now()

        // Check if rating already exists for this user+store
        let result = case dict.get(state.user_store_index, key) {
          Ok(existing_id) -> {
            // Update existing rating
            case dict.get(state.ratings, existing_id) {
              Ok(existing) -> {
                let updated = shared.Rating(
                  id: existing.id,
                  store_id: existing.store_id,
                  user_id: existing.user_id,
                  overall_score: overall_score,
                  review_text: review_text,
                  created_at: existing.created_at,
                  updated_at: current_time,
                )
                let new_ratings = dict.insert(state.ratings, existing.id, updated)
                Ok(#(updated, RatingState(..state, ratings: new_ratings)))
              }
              Error(_) -> Error(InternalError("Inconsistent index state"))
            }
          }
          Error(_) -> {
            // Create new rating
            let id = "rating_" <> int_to_string(state.next_id)
            let new_rating = shared.Rating(
              id: id,
              store_id: store_id,
              user_id: user_id,
              overall_score: overall_score,
              review_text: review_text,
              created_at: current_time,
              updated_at: current_time,
            )
            let new_ratings = dict.insert(state.ratings, id, new_rating)
            let new_index = dict.insert(state.user_store_index, key, id)
            let new_state = RatingState(
              ratings: new_ratings,
              user_store_index: new_index,
              next_id: state.next_id + 1,
            )
            Ok(#(new_rating, new_state))
          }
        }

        case result {
          Ok(#(rating, new_state)) -> {
            process.send(reply, Ok(rating))
            actor.continue(new_state)
          }
          Error(err) -> {
            process.send(reply, Error(err))
            actor.continue(state)
          }
        }
      }

      GetRatingForUserAndStore(store_id, user_id, reply) -> {
        let key = make_key(store_id, user_id)
        let result = case dict.get(state.user_store_index, key) {
          Ok(rating_id) -> {
            case dict.get(state.ratings, rating_id) {
              Ok(rating) -> Ok(rating)
              Error(_) -> Error(NotFound("rating"))
            }
          }
          Error(_) -> Error(NotFound("rating"))
        }
        process.send(reply, result)
        actor.continue(state)
      }

      GetRatingsForStore(store_id, reply) -> {
        let ratings = dict.values(state.ratings)
          |> filter_ratings_by_store(store_id, [])
        process.send(reply, ratings)
        actor.continue(state)
      }

      Shutdown -> actor.stop()
    }
  }

  actor.new(initial_state())
  |> actor.on_message(handler)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start rating actor" })
}

fn filter_ratings_by_store(ratings: List(Rating), store_id: String, acc: List(Rating)) -> List(Rating) {
  case ratings {
    [] -> acc
    [rating, ..rest] -> {
      let new_acc = case rating.store_id == store_id {
        True -> [rating, ..acc]
        False -> acc
      }
      filter_ratings_by_store(rest, store_id, new_acc)
    }
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    n if n < 0 -> "-" <> int_to_string(-n)
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      do_int_to_string(n / 10, digit <> acc)
    }
  }
}

/// Public API functions

pub fn create_rating(
  actor: RatingActor,
  store_id: String,
  user_id: String,
  overall_score: Int,
  review_text: Option(String),
) -> Result(Rating, AppError) {
  let reply_subject = process.new_subject()
  process.send(actor, CreateRating(store_id, user_id, overall_score, review_text, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.unwrap(Error(InternalError("Timeout")))
}

pub fn get_rating_with_user(
  rating_actor: RatingActor,
  user_actor: UserActor,
  store_id: String,
  user_id: String,
) -> Result(RatingWithUser, AppError) {
  // Get rating
  let reply_subject = process.new_subject()
  process.send(rating_actor, GetRatingForUserAndStore(store_id, user_id, reply_subject))
  let rating_result = process.receive(reply_subject, 5000)
    |> result.unwrap(Error(InternalError("Timeout")))

  case rating_result {
    Error(err) -> Error(err)
    Ok(rating) -> {
      // Get user info
      case user.get_user(user_actor, rating.user_id) {
        Error(err) -> Error(err)
        Ok(user) -> {
          Ok(shared.RatingWithUser(
            id: rating.id,
            store_id: rating.store_id,
            user_id: rating.user_id,
            user: user,
            overall_score: rating.overall_score,
            review_text: rating.review_text,
            created_at: rating.created_at,
            updated_at: rating.updated_at,
          ))
        }
      }
    }
  }
}

pub fn stop(actor: RatingActor) -> Nil {
  process.send(actor, Shutdown)
}
