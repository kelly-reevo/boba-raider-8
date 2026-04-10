/// In-memory storage for drink ratings

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/string
import shared.{type Rating, type PaginationMeta}

/// Store message types
pub type StoreMsg {
  GetByDrink(
    drink_id: String,
    page: Int,
    limit: Int,
    reply_to: Subject(Result(PaginatedRatings, String)),
  )
  GetDrinkRatingCount(drink_id: String, reply_to: Subject(Int))
  Insert(Rating)
}

/// Paginated ratings result
pub type PaginatedRatings {
  PaginatedRatings(ratings: List(Rating), meta: PaginationMeta)
}

/// Store state
pub type StoreState {
  StoreState(ratings: Dict(String, Rating))
}

/// Store actor reference
pub type RatingsStore =
  Subject(StoreMsg)

/// Start the ratings store actor
pub fn start() -> Result(RatingsStore, String) {
  let initial_state = StoreState(ratings: dict.new())

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start ratings store")
  }
}

/// Handle store messages
fn handle_message(
  state: StoreState,
  msg: StoreMsg,
) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    GetByDrink(drink_id, page, limit, reply_to) -> {
      let result = get_by_drink_internal(state, drink_id, page, limit)
      process.send(reply_to, result)
      actor.continue(state)
    }

    GetDrinkRatingCount(drink_id, reply_to) -> {
      let count = get_count_internal(state, drink_id)
      process.send(reply_to, count)
      actor.continue(state)
    }

    Insert(rating) -> {
      let new_state =
        StoreState(ratings: dict.insert(state.ratings, rating.id, rating))
      actor.continue(new_state)
    }
  }
}

/// Get paginated ratings for a drink
fn get_by_drink_internal(
  state: StoreState,
  drink_id: String,
  page: Int,
  limit: Int,
) -> Result(PaginatedRatings, String) {
  let all_ratings =
    dict.values(state.ratings)
    |> list.filter(fn(r) { r.drink_id == drink_id })
    |> list.sort(fn(a, b) { string.compare(b.created_at, a.created_at) })

  let total = list.length(all_ratings)
  let offset = { page - 1 } * limit

  let paginated =
    all_ratings
    |> list.drop(offset)
    |> list.take(limit)

  let total_pages = case total % limit {
    0 -> total / limit
    _ -> total / limit + 1
  }

  let meta = shared.PaginationMeta(total: total, page: page, limit: limit, total_pages: total_pages)

  Ok(PaginatedRatings(ratings: paginated, meta: meta))
}

/// Get total count of ratings for a drink
fn get_count_internal(state: StoreState, drink_id: String) -> Int {
  dict.values(state.ratings)
  |> list.filter(fn(r) { r.drink_id == drink_id })
  |> list.length
}

/// Public API: Get ratings for a drink with pagination
pub fn get_by_drink(
  store: RatingsStore,
  drink_id: String,
  page: Int,
  limit: Int,
) -> Result(PaginatedRatings, String) {
  process.call(
    store,
    5000,
    fn(subject) { GetByDrink(drink_id, page, limit, subject) },
  )
}

/// Public API: Check if drink has any ratings
pub fn has_ratings(store: RatingsStore, drink_id: String) -> Bool {
  let count = process.call(
    store,
    5000,
    fn(subject) { GetDrinkRatingCount(drink_id, subject) },
  )
  count > 0
}

/// Public API: Insert a rating
pub fn insert(store: RatingsStore, rating: Rating) -> Nil {
  process.send(store, Insert(rating))
}
