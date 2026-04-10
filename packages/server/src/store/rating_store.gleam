/// In-memory rating storage using OTP actor

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor
import rating.{type Rating}

pub type RatingStoreMsg {
  Get(rating_id: String, reply_to: Subject(Result(Rating, Nil)))
  Delete(rating_id: String, reply_to: Subject(Bool))
  GetStoreRatings(store_id: String, reply_to: Subject(List(Rating)))
  Insert(rating: Rating, reply_to: Subject(Nil))
  GetStoreAverage(store_id: String, reply_to: Subject(Result(Float, Nil)))
}

pub type RatingStore =
  Subject(RatingStoreMsg)

fn recalculate_store_average(
  ratings: Dict(String, Rating),
  store_id: String,
) -> Result(Float, Nil) {
  let store_ratings =
    ratings
    |> dict.values()
    |> list.filter(fn(r) { r.store_id == store_id })

  case store_ratings {
    [] -> Error(Nil)
    ratings_list -> {
      let sum = list.fold(ratings_list, 0, fn(acc, r) { acc + r.score })
      Ok(int.to_float(sum) /. int.to_float(list.length(ratings_list)))
    }
  }
}

fn handle_message(
  state: Dict(String, Rating),
  msg: RatingStoreMsg,
) -> actor.Next(Dict(String, Rating), RatingStoreMsg) {
  case msg {
    Get(rating_id, reply_to) -> {
      let result = dict.get(state, rating_id)
      process.send(reply_to, result)
      actor.continue(state)
    }

    Delete(rating_id, reply_to) -> {
      let exists = dict.has_key(state, rating_id)
      process.send(reply_to, exists)
      let new_state = dict.delete(state, rating_id)
      actor.continue(new_state)
    }

    GetStoreRatings(store_id, reply_to) -> {
      let ratings =
        state
        |> dict.values()
        |> list.filter(fn(r) { r.store_id == store_id })
      process.send(reply_to, ratings)
      actor.continue(state)
    }

    Insert(rating, reply_to) -> {
      process.send(reply_to, Nil)
      actor.continue(dict.insert(state, rating.id, rating))
    }

    GetStoreAverage(store_id, reply_to) -> {
      let avg = recalculate_store_average(state, store_id)
      process.send(reply_to, avg)
      actor.continue(state)
    }
  }
}

pub fn start() -> Result(RatingStore, String) {
  let builder =
    actor.new(dict.new())
    |> actor.on_message(handle_message)

  case actor.start(builder) {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start rating store actor")
  }
}

pub fn get(store: RatingStore, rating_id: String) -> Result(Rating, Nil) {
  process.call(store, 5000, Get(rating_id, _))
}

pub fn delete(store: RatingStore, rating_id: String) -> Bool {
  process.call(store, 5000, Delete(rating_id, _))
}

pub fn get_store_average(
  store: RatingStore,
  store_id: String,
) -> Result(Float, Nil) {
  process.call(store, 5000, GetStoreAverage(store_id, _))
}

pub fn insert(store: RatingStore, rating: Rating) -> Nil {
  process.call(store, 5000, Insert(rating, _))
}
