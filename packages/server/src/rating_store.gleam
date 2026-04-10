/// In-memory rating storage using OTP actor
/// Simple dict-backed storage for ratings

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import shared.{type Rating, type RatingError}

/// Storage key: drink_id + user_id composite
pub type RatingKey {
  RatingKey(drink_id: String, user_id: String)
}

/// Internal state: dict of ratings by composite key
pub type StoreState {
  StoreState(ratings: Dict(RatingKey, Rating))
}

/// Messages the store actor handles
pub type StoreMsg {
  GetByDrinkAndUser(
    drink_id: String,
    user_id: String,
    reply_to: Subject(Option(Rating)),
  )
  CreateRating(rating: Rating, reply_to: Subject(Result(Rating, RatingError)))
  GetAllForDrink(drink_id: String, reply_to: Subject(List(Rating)))
  DeleteRating(drink_id: String, user_id: String, reply_to: Subject(Bool))
  Shutdown
}

/// Store handle - opaque wrapper around the actor subject
pub opaque type RatingStore {
  RatingStore(subject: Subject(StoreMsg))
}

/// Get the subject from the store
fn subject(store: RatingStore) -> Subject(StoreMsg) {
  store.subject
}

/// Create composite key from drink and user IDs
fn make_key(drink_id: String, user_id: String) -> RatingKey {
  RatingKey(drink_id:, user_id:)
}

/// Actor message handler
fn handle_message(
  state: StoreState,
  msg: StoreMsg,
) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    GetByDrinkAndUser(drink_id, user_id, reply) -> {
      let key = make_key(drink_id, user_id)
      let rating_result = dict.get(state.ratings, key)
      let rating_option = case rating_result {
        Ok(r) -> Some(r)
        Error(_) -> None
      }
      process.send(reply, rating_option)
      actor.continue(state)
    }

    CreateRating(rating, reply) -> {
      let key = make_key(rating.drink_id, rating.user_id)
      // Check for duplicate
      case dict.has_key(state.ratings, key) {
        True -> {
          process.send(reply, Error(shared.DuplicateRating))
          actor.continue(state)
        }
        False -> {
          let new_ratings = dict.insert(state.ratings, key, rating)
          process.send(reply, Ok(rating))
          actor.continue(StoreState(new_ratings))
        }
      }
    }

    GetAllForDrink(drink_id, reply) -> {
      let ratings =
        dict.filter(state.ratings, fn(key, _) { key.drink_id == drink_id })
        |> dict.values
      process.send(reply, ratings)
      actor.continue(state)
    }

    DeleteRating(drink_id, user_id, reply) -> {
      let key = make_key(drink_id, user_id)
      let existed = dict.has_key(state.ratings, key)
      let new_ratings = dict.delete(state.ratings, key)
      process.send(reply, existed)
      actor.continue(StoreState(new_ratings))
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

/// Start the rating store actor
pub fn start() -> Result(RatingStore, String) {
  let initial_state = StoreState(dict.new())

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(RatingStore(started.data))
    Error(_) -> Error("Failed to start rating store")
  }
}

/// Stop the store
pub fn stop(store: RatingStore) -> Nil {
  process.send(subject(store), Shutdown)
}

/// Get a rating by drink and user ID
pub fn get_by_drink_and_user(
  store: RatingStore,
  drink_id: String,
  user_id: String,
) -> Option(Rating) {
  let reply = process.new_subject()
  process.send(subject(store), GetByDrinkAndUser(drink_id, user_id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(None)
}

/// Create a new rating (fails if duplicate)
pub fn create_rating(
  store: RatingStore,
  rating: Rating,
) -> Result(Rating, RatingError) {
  let reply = process.new_subject()
  process.send(subject(store), CreateRating(rating, reply))
  process.receive(reply, 5000)
  |> result.map_error(fn(_) { shared.RatingStoreError("Store timeout") })
  |> result.flatten
}

/// Get all ratings for a drink
pub fn get_all_for_drink(store: RatingStore, drink_id: String) -> List(Rating) {
  let reply = process.new_subject()
  process.send(subject(store), GetAllForDrink(drink_id, reply))
  process.receive(reply, 5000)
  |> result.unwrap([])
}

/// Delete a rating
pub fn delete_rating(
  store: RatingStore,
  drink_id: String,
  user_id: String,
) -> Bool {
  let reply = process.new_subject()
  process.send(subject(store), DeleteRating(drink_id, user_id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(False)
}
