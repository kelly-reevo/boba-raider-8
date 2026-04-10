/// Drink data access layer - in-memory storage using OTP actor

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import shared.{type CreateDrinkInput, type Drink, Conflict, Drink}

/// State for the drink store actor
type StoreState {
  StoreState(drinks: Dict(String, Drink), next_id: Int)
}

/// Messages the drink store actor can receive
pub type StoreMessage {
  CreateDrink(
    store_id: String,
    input: CreateDrinkInput,
    reply_to: Subject(Result(Drink, shared.AppError)),
  )
  GetDrinkById(
    id: String,
    reply_to: Subject(Option(Drink)),
  )
  GetDrinksByStore(
    store_id: String,
    reply_to: Subject(List(Drink)),
  )
}

/// Handle messages for the drink store actor
fn handle_message(
  state: StoreState,
  msg: StoreMessage,
) -> actor.Next(StoreState, StoreMessage) {
  case msg {
    CreateDrink(store_id, input, reply_to) -> {
      let result = do_create_drink(state, store_id, input)
      case result {
        Ok(#(drink, new_state)) -> {
          process.send(reply_to, Ok(drink))
          actor.continue(new_state)
        }
        Error(err) -> {
          process.send(reply_to, Error(err))
          actor.continue(state)
        }
      }
    }
    GetDrinkById(id, reply_to) -> {
      let drink = dict.get(state.drinks, id) |> option.from_result
      process.send(reply_to, drink)
      actor.continue(state)
    }
    GetDrinksByStore(store_id, reply_to) -> {
      let drinks =
        state.drinks
        |> dict.values()
        |> list.filter(fn(d) { d.store_id == store_id })
      process.send(reply_to, drinks)
      actor.continue(state)
    }
  }
}

fn do_create_drink(
  state: StoreState,
  store_id: String,
  input: CreateDrinkInput,
) -> Result(#(Drink, StoreState), shared.AppError) {
  // Check for duplicate drink name in the same store
  let existing =
    state.drinks
    |> dict.values()
    |> list.any(fn(d) { d.store_id == store_id && d.name == input.name })

  case existing {
    True -> Error(Conflict("Drink with this name already exists in store"))
    False -> {
      let id = "drink_" <> int_to_string(state.next_id)
      let now = "2026-04-10T00:00:00Z" // Simplified timestamp

      let drink =
        Drink(
          id: id,
          store_id: store_id,
          name: input.name,
          tea_type: input.tea_type,
          price: input.price,
          description: input.description,
          image_url: input.image_url,
          is_signature: input.is_signature,
          created_at: now,
          average_rating: shared.AverageRating(
            overall: None,
            sweetness: None,
            texture: None,
            tea_strength: None,
          ),
        )

      let new_state =
        StoreState(
          drinks: dict.insert(state.drinks, id, drink),
          next_id: state.next_id + 1,
        )

      Ok(#(drink, new_state))
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

/// Start the drink store actor
pub fn start() -> Subject(StoreMessage) {
  let initial_state = StoreState(drinks: dict.new(), next_id: 1)

  let assert Ok(started) =
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()

  started.data
}

/// Public API functions

pub fn create_drink(
  store: Subject(StoreMessage),
  store_id: String,
  input: CreateDrinkInput,
) -> Result(Drink, shared.AppError) {
  let reply_subject = process.new_subject()
  process.send(store, CreateDrink(store_id, input, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.lazy_unwrap(fn() { Error(shared.InternalError("Store timeout")) })
}

pub fn get_drink(
  store: Subject(StoreMessage),
  id: String,
) -> Option(Drink) {
  let reply_subject = process.new_subject()
  process.send(store, GetDrinkById(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.lazy_unwrap(fn() { None })
}

pub fn get_drinks_by_store(
  store: Subject(StoreMessage),
  store_id: String,
) -> List(Drink) {
  let reply_subject = process.new_subject()
  process.send(store, GetDrinksByStore(store_id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.lazy_unwrap(fn() { [] })
}
