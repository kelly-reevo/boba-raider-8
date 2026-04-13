/// Main store interface for boba-raider-8
/// Coordinates drink_store, rating_service, and store_data_access

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor

// Dependencies
import boba_types.{type Drink, type Rating, type Store}
import boba_validation.{type DrinkInput, type RatingInput, type StoreInput}

/// Internal drink record with timestamp
pub type DrinkRecord {
  DrinkRecord(
    id: Int,
    store_id: Int,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    created_at: String,
  )
}

/// Internal store record
pub type StoreRecord {
  StoreRecord(
    id: Int,
    name: String,
    address: Option(String),
    phone: Option(String),
    created_at: String,
  )
}

/// Internal rating record
pub type RatingRecord {
  RatingRecord(
    id: Int,
    drink_id: Int,
    rating: Int,
    sweetness: Int,
    boba_texture: Int,
    tea_strength: Int,
    created_at: String,
  )
}

/// Rating aggregates for a drink
pub type RatingAggregates {
  RatingAggregates(
    overall_rating: Float,
    sweetness: Float,
    boba_texture: Float,
    tea_strength: Float,
    count: Int,
  )
}

/// Store message types for actor
pub type BobaStoreMsg {
  CreateStore(StoreInput, Subject(Result(Store, String)))
  GetStoreById(Int, Subject(Result(Store, String)))
  CreateDrink(DrinkInput, Subject(Result(Drink, String)))
  GetDrinkById(Int, Subject(Result(DrinkRecord, String)))
  CreateRating(RatingInput, Subject(Result(Rating, String)))
  GetRatingAggregates(Int, Subject(RatingAggregates))
  Shutdown
}

/// Store handle (actor subject)
pub type BobaStore =
  Subject(BobaStoreMsg)

/// Store state
pub opaque type StoreState {
  StoreState(
    stores: Dict(Int, StoreRecord),
    drinks: Dict(Int, DrinkRecord),
    ratings: Dict(Int, RatingRecord),
    next_store_id: Int,
    next_drink_id: Int,
    next_rating_id: Int,
  )
}

/// Generate ISO8601 timestamp
fn current_timestamp() -> String {
  "2026-04-12T00:00:00Z"
}

/// Actor message handler
fn handle_message(state: StoreState, msg: BobaStoreMsg) -> actor.Next(StoreState, BobaStoreMsg) {
  case msg {
    CreateStore(input, reply_to) -> {
      let id = state.next_store_id
      let record = StoreRecord(
        id: id,
        name: input.name,
        address: input.address,
        phone: input.phone,
        created_at: current_timestamp(),
      )
      let new_stores = dict.insert(state.stores, id, record)
      let new_state = StoreState(
        ..state,
        stores: new_stores,
        next_store_id: id + 1,
      )
      // Construct Store type from boba_types using record syntax
      let store: Store = boba_types.Store(
        id: id,
        name: input.name,
        address: option.unwrap(input.address, ""),
        created_at: current_timestamp(),
      )
      actor.send(reply_to, Ok(store))
      actor.continue(new_state)
    }

    GetStoreById(id, reply_to) -> {
      case dict.get(state.stores, id) {
        Ok(record) -> {
          let store: Store = boba_types.Store(
            id: record.id,
            name: record.name,
            address: option.unwrap(record.address, ""),
            created_at: record.created_at,
          )
          actor.send(reply_to, Ok(store))
        }
        Error(_) -> {
          actor.send(reply_to, Error("Store not found"))
        }
      }
      actor.continue(state)
    }

    CreateDrink(input, reply_to) -> {
      // Verify store exists
      case dict.get(state.stores, input.store_id) {
        Ok(_) -> {
          let id = state.next_drink_id
          let record = DrinkRecord(
            id: id,
            store_id: input.store_id,
            name: input.name,
            description: None,
            base_tea_type: None,
            price: None,
            created_at: current_timestamp(),
          )
          let new_drinks = dict.insert(state.drinks, id, record)
          let new_state = StoreState(
            ..state,
            drinks: new_drinks,
            next_drink_id: id + 1,
          )
          let drink: Drink = boba_types.Drink(
            id: id,
            store_id: input.store_id,
            name: input.name,
            description: "",
            base_tea_type: "",
            price: 0.0,
            created_at: current_timestamp(),
          )
          actor.send(reply_to, Ok(drink))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Store not found"))
          actor.continue(state)
        }
      }
    }

    GetDrinkById(id, reply_to) -> {
      case dict.get(state.drinks, id) {
        Ok(record) -> {
          actor.send(reply_to, Ok(record))
        }
        Error(_) -> {
          actor.send(reply_to, Error("Drink not found"))
        }
      }
      actor.continue(state)
    }

    CreateRating(input, reply_to) -> {
      // Verify drink exists
      case dict.get(state.drinks, input.drink_id) {
        Ok(_) -> {
          let id = state.next_rating_id
          let record = RatingRecord(
            id: id,
            drink_id: input.drink_id,
            rating: input.rating,
            sweetness: input.sweetness,
            boba_texture: input.boba_texture,
            tea_strength: input.tea_strength,
            created_at: current_timestamp(),
          )
          let new_ratings = dict.insert(state.ratings, id, record)
          let new_state = StoreState(
            ..state,
            ratings: new_ratings,
            next_rating_id: id + 1,
          )
          let rating: Rating = boba_types.Rating(
            id: id,
            drink_id: input.drink_id,
            overall_rating: input.rating,
            sweetness: input.sweetness,
            boba_texture: input.boba_texture,
            tea_strength: input.tea_strength,
            created_at: current_timestamp(),
          )
          actor.send(reply_to, Ok(rating))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Drink not found"))
          actor.continue(state)
        }
      }
    }

    GetRatingAggregates(drink_id, reply_to) -> {
      let drink_ratings =
        state.ratings
        |> dict.values()
        |> list.filter(fn(r) { r.drink_id == drink_id })

      let count = list.length(drink_ratings)

      let aggregates = case count {
        0 -> RatingAggregates(
          overall_rating: 0.0,
          sweetness: 0.0,
          boba_texture: 0.0,
          tea_strength: 0.0,
          count: 0,
        )
        _ -> {
          let sum_overall = list.fold(drink_ratings, 0, fn(acc, r) { acc + r.rating })
          let sum_sweetness = list.fold(drink_ratings, 0, fn(acc, r) { acc + r.sweetness })
          let sum_texture = list.fold(drink_ratings, 0, fn(acc, r) { acc + r.boba_texture })
          let sum_strength = list.fold(drink_ratings, 0, fn(acc, r) { acc + r.tea_strength })

          let count_float = int.to_float(count)

          RatingAggregates(
            overall_rating: int.to_float(sum_overall) /. count_float,
            sweetness: int.to_float(sum_sweetness) /. count_float,
            boba_texture: int.to_float(sum_texture) /. count_float,
            tea_strength: int.to_float(sum_strength) /. count_float,
            count: count,
          )
        }
      }

      actor.send(reply_to, aggregates)
      actor.continue(state)
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

// ============================================================================
// Public API
// ============================================================================

/// Start a new boba store actor
pub fn new() -> Result(BobaStore, String) {
  let initial_state = StoreState(
    stores: dict.new(),
    drinks: dict.new(),
    ratings: dict.new(),
    next_store_id: 1,
    next_drink_id: 1,
    next_rating_id: 1,
  )

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start boba store actor")
  }
}

/// Create a new store
pub fn create_store(store: BobaStore, input: StoreInput) -> Result(Store, String) {
  let reply_subject = process.new_subject()
  actor.send(store, CreateStore(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store creation")
  }
}

/// Get a store by ID
pub fn get_store_by_id(store: BobaStore, id: Int) -> Result(Store, String) {
  let reply_subject = process.new_subject()
  actor.send(store, GetStoreById(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store lookup")
  }
}

/// Create a new drink
pub fn create_drink(store: BobaStore, input: DrinkInput) -> Result(Drink, String) {
  let reply_subject = process.new_subject()
  actor.send(store, CreateDrink(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink creation")
  }
}

/// Get a drink by ID (internal record)
pub fn get_drink_by_id(store: BobaStore, id: Int) -> Result(DrinkRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, GetDrinkById(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink lookup")
  }
}

/// Create a new rating
pub fn create_rating(store: BobaStore, input: RatingInput) -> Result(Rating, String) {
  let reply_subject = process.new_subject()
  actor.send(store, CreateRating(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for rating creation")
  }
}

/// Get rating aggregates for a drink
pub fn get_rating_aggregates(store: BobaStore, drink_id: Int) -> RatingAggregates {
  let reply_subject = process.new_subject()
  actor.send(store, GetRatingAggregates(drink_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(aggregates) -> aggregates
    Error(_) -> RatingAggregates(0.0, 0.0, 0.0, 0.0, 0)
  }
}
