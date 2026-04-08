import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/list
import gleam/otp/actor
import shared.{type AggregatedRating, type Rating, AggregatedRating}

pub type RatingStoreMsg {
  Submit(rating: Rating, reply: Subject(Result(Rating, String)))
  GetByDrink(drink_id: String, reply: Subject(List(Rating)))
  GetAggregated(drink_id: String, reply: Subject(Result(AggregatedRating, String)))
}

pub type RatingStore =
  Subject(RatingStoreMsg)

type State =
  Dict(String, List(Rating))

pub fn start() -> Result(RatingStore, String) {
  let init_state: State = dict.new()
  case
    actor.new(init_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start rating store")
  }
}

fn handle_message(state: State, msg: RatingStoreMsg) -> actor.Next(State, RatingStoreMsg) {
  case msg {
    Submit(rating, reply) -> {
      let existing = case dict.get(state, rating.drink_id) {
        Ok(ratings) -> ratings
        Error(_) -> []
      }
      let new_state = dict.insert(state, rating.drink_id, [rating, ..existing])
      actor.send(reply, Ok(rating))
      actor.continue(new_state)
    }

    GetByDrink(drink_id, reply) -> {
      let ratings = case dict.get(state, drink_id) {
        Ok(r) -> r
        Error(_) -> []
      }
      actor.send(reply, ratings)
      actor.continue(state)
    }

    GetAggregated(drink_id, reply) -> {
      case dict.get(state, drink_id) {
        Ok(ratings) -> {
          let agg = aggregate(drink_id, ratings)
          actor.send(reply, Ok(agg))
        }
        Error(_) -> {
          actor.send(reply, Error("No ratings found for drink"))
        }
      }
      actor.continue(state)
    }
  }
}

fn aggregate(drink_id: String, ratings: List(Rating)) -> AggregatedRating {
  let count = list.length(ratings)
  let fc = int.to_float(count)
  let sum_sweetness =
    list.fold(ratings, 0, fn(acc, r) { acc + r.sweetness }) |> int.to_float
  let sum_texture =
    list.fold(ratings, 0, fn(acc, r) { acc + r.texture }) |> int.to_float
  let sum_flavor =
    list.fold(ratings, 0, fn(acc, r) { acc + r.flavor }) |> int.to_float
  let sum_overall =
    list.fold(ratings, 0, fn(acc, r) { acc + r.overall }) |> int.to_float
  AggregatedRating(
    drink_id: drink_id,
    avg_sweetness: float.divide(sum_sweetness, fc) |> unwrap_float,
    avg_texture: float.divide(sum_texture, fc) |> unwrap_float,
    avg_flavor: float.divide(sum_flavor, fc) |> unwrap_float,
    avg_overall: float.divide(sum_overall, fc) |> unwrap_float,
    count: count,
  )
}

fn unwrap_float(result: Result(Float, Nil)) -> Float {
  case result {
    Ok(v) -> v
    Error(_) -> 0.0
  }
}
