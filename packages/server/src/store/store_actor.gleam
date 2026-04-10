import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/result
import shared.{type AppError, NotFound}

// Public types
pub type StoreId = String
pub type DrinkId = String
pub type RatingId = String

pub type Store {
  Store(id: String, name: String, creator_id: String, created_at: String)
}

pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    description: String,
    created_at: String,
  )
}

pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    user_id: String,
    score: Int,
    comment: String,
    created_at: String,
  )
}

// Internal state
pub opaque type StoreState {
  StoreState(
    stores: Dict(StoreId, Store),
    drinks: Dict(DrinkId, Drink),
    ratings: Dict(RatingId, Rating),
  )
}

// Messages
pub type StoreMessage {
  GetStore(id: StoreId, reply: Subject(Result(Store, AppError)))
  DeleteStore(id: StoreId, reply: Subject(Result(Nil, AppError)))
  GetDrinksByStore(store_id: StoreId, reply: Subject(List(Drink)))
  DeleteDrink(id: DrinkId, reply: Subject(Result(Nil, Nil)))
  GetRatingsByDrink(drink_id: DrinkId, reply: Subject(List(Rating)))
  DeleteRating(id: RatingId, reply: Subject(Result(Nil, Nil)))
}

pub fn new() -> StoreState {
  StoreState(
    stores: dict.new(),
    drinks: dict.new(),
    ratings: dict.new(),
  )
}

pub fn handle_message(state: StoreState, message: StoreMessage) {
  case message {
    GetStore(id, reply) -> {
      let result = dict.get(state.stores, id)
      case result {
        Ok(store) -> process.send(reply, Ok(store))
        Error(_) -> process.send(reply, Error(NotFound("store")))
      }
      actor.continue(state)
    }

    DeleteStore(id, reply) -> {
      let result = dict.get(state.stores, id)
      case result {
        Ok(_) -> {
          // Cascade: delete all drinks for this store
          let drinks_to_delete =
            state.drinks
            |> dict.values()
            |> list.filter(fn(d) { d.store_id == id })

          // Delete ratings for each drink
          let new_ratings =
            drinks_to_delete
            |> list.fold(state.ratings, fn(acc, drink) {
              state.ratings
              |> dict.values()
              |> list.filter(fn(r) { r.drink_id == drink.id })
              |> list.fold(acc, fn(acc2, rating) {
                dict.delete(acc2, rating.id)
              })
            })

          // Delete drinks
          let new_drinks =
            drinks_to_delete
            |> list.fold(state.drinks, fn(acc, drink) {
              dict.delete(acc, drink.id)
            })

          // Delete store
          let new_stores = dict.delete(state.stores, id)

          process.send(reply, Ok(Nil))
          actor.continue(
            StoreState(stores: new_stores, drinks: new_drinks, ratings: new_ratings),
          )
        }
        Error(_) -> {
          process.send(reply, Error(NotFound("store")))
          actor.continue(state)
        }
      }
    }

    GetDrinksByStore(store_id, reply) -> {
      let drinks =
        state.drinks
        |> dict.values()
        |> list.filter(fn(d) { d.store_id == store_id })
      process.send(reply, drinks)
      actor.continue(state)
    }

    DeleteDrink(id, reply) -> {
      let new_drinks = dict.delete(state.drinks, id)
      process.send(reply, Ok(Nil))
      actor.continue(StoreState(..state, drinks: new_drinks))
    }

    GetRatingsByDrink(drink_id, reply) -> {
      let ratings =
        state.ratings
        |> dict.values()
        |> list.filter(fn(r) { r.drink_id == drink_id })
      process.send(reply, ratings)
      actor.continue(state)
    }

    DeleteRating(id, reply) -> {
      let new_ratings = dict.delete(state.ratings, id)
      process.send(reply, Ok(Nil))
      actor.continue(StoreState(..state, ratings: new_ratings))
    }
  }
}

// Public API functions

pub fn get_store(
  actor_ref: Subject(StoreMessage),
  id: StoreId,
) -> Result(Store, AppError) {
  let reply_subject = process.new_subject()
  process.send(actor_ref, GetStore(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.replace_error(NotFound("timeout"))
  |> result.flatten()
}

pub fn delete_store(
  actor_ref: Subject(StoreMessage),
  id: StoreId,
) -> Result(Nil, AppError) {
  let reply_subject = process.new_subject()
  process.send(actor_ref, DeleteStore(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.replace_error(NotFound("timeout"))
  |> result.flatten()
}
