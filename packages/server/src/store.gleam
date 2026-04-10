/// Simple ETS-based storage for ratings
/// Simplicity bias: Single ETS table, no complex abstractions

import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import shared.{type Rating, type AppError, NotFound, InternalError}

/// Storage actor message types
pub type StoreMsg {
  GetRating(id: String, reply: Subject(Option(Rating)))
  SaveRating(rating: Rating, reply: Subject(Result(Nil, AppError)))
  DeleteRating(id: String, reply: Subject(Result(Nil, AppError)))
  ListRatingsForDrink(drink_id: String, reply: Subject(List(Rating)))
  ListRatingsForUser(user_id: String, reply: Subject(List(Rating)))
}

/// Storage handle
pub type Store =
  Subject(StoreMsg)

/// State holds ratings in memory using a dict (simplest approach)
pub type State {
  State(ratings: dict.Dict(String, Rating))
}

/// Start the storage actor
pub fn start() -> Result(Store, String) {
  let initial_state = State(ratings: dict.new())

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start store actor" })
}

/// Handle incoming messages
fn handle_message(state: State, msg: StoreMsg) {
  case msg {
    GetRating(id, reply) -> {
      let rating = dict.get(state.ratings, id) |> option.from_result
      actor.send(reply, rating)
      actor.continue(state)
    }

    SaveRating(rating, reply) -> {
      let new_ratings = dict.insert(state.ratings, rating.id, rating)
      actor.send(reply, Ok(Nil))
      actor.continue(State(ratings: new_ratings))
    }

    DeleteRating(id, reply) -> {
      case dict.has_key(state.ratings, id) {
        True -> {
          let new_ratings = dict.delete(state.ratings, id)
          actor.send(reply, Ok(Nil))
          actor.continue(State(ratings: new_ratings))
        }
        False -> {
          actor.send(reply, Error(NotFound("Rating not found")))
          actor.continue(state)
        }
      }
    }

    ListRatingsForDrink(drink_id, reply) -> {
      let ratings =
        dict.values(state.ratings)
        |> list.filter(fn(r) { r.drink_id == drink_id })
      actor.send(reply, ratings)
      actor.continue(state)
    }

    ListRatingsForUser(user_id, reply) -> {
      let ratings =
        dict.values(state.ratings)
        |> list.filter(fn(r) { r.user_id == user_id })
      actor.send(reply, ratings)
      actor.continue(state)
    }
  }
}

/// Public API functions

/// Get a rating by ID
pub fn get_rating(store: Store, id: String) -> Option(Rating) {
  let reply = process.new_subject()
  actor.send(store, GetRating(id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(None)
}

/// Save a rating (insert or update)
pub fn save_rating(store: Store, rating: Rating) -> Result(Nil, AppError) {
  let reply = process.new_subject()
  actor.send(store, SaveRating(rating, reply))
  process.receive(reply, 5000)
  |> result.unwrap(Error(InternalError("Store timeout")))
}

/// Delete a rating
pub fn delete_rating(store: Store, id: String) -> Result(Nil, AppError) {
  let reply = process.new_subject()
  actor.send(store, DeleteRating(id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(Error(InternalError("Store timeout")))
}

/// List all ratings for a drink
pub fn list_ratings_for_drink(store: Store, drink_id: String) -> List(Rating) {
  let reply = process.new_subject()
  actor.send(store, ListRatingsForDrink(drink_id, reply))
  process.receive(reply, 5000)
  |> result.unwrap([])
}

/// List all ratings for a user
pub fn list_ratings_for_user(store: Store, user_id: String) -> List(Rating) {
  let reply = process.new_subject()
  actor.send(store, ListRatingsForUser(user_id, reply))
  process.receive(reply, 5000)
  |> result.unwrap([])
}
