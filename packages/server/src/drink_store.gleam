import drink.{type Drink, Drink}
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result

pub opaque type DrinkStore {
  DrinkStore(subject: Subject(Msg))
}

type Msg {
  ListDrinks(store_id: String, reply: Subject(List(Drink)))
  GetDrink(id: String, reply: Subject(Result(Drink, Nil)))
  CreateDrink(
    store_id: String,
    name: String,
    description: String,
    price_cents: Int,
    category: String,
    available: Bool,
    reply: Subject(Drink),
  )
  UpdateDrink(drink: Drink, reply: Subject(Result(Drink, Nil)))
  DeleteDrink(id: String, reply: Subject(Result(Nil, Nil)))
}

type State {
  State(drinks: Dict(String, Drink), next_id: Int)
}

pub fn start() -> Result(DrinkStore, actor.StartError) {
  actor.new(State(dict.new(), 1))
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { DrinkStore(started.data) })
}

fn handle_message(state: State, msg: Msg) -> actor.Next(State, Msg) {
  case msg {
    ListDrinks(store_id, reply) -> {
      let filtered =
        state.drinks
        |> dict.values
        |> list.filter(fn(d) { d.store_id == store_id })
      process.send(reply, filtered)
      actor.continue(state)
    }

    GetDrink(id, reply) -> {
      process.send(reply, dict.get(state.drinks, id))
      actor.continue(state)
    }

    CreateDrink(store_id, name, description, price_cents, category, available, reply) -> {
      let id = "drink_" <> int.to_string(state.next_id)
      let new_drink =
        Drink(id, store_id, name, description, price_cents, category, available)
      let new_drinks = dict.insert(state.drinks, id, new_drink)
      process.send(reply, new_drink)
      actor.continue(State(new_drinks, state.next_id + 1))
    }

    UpdateDrink(updated, reply) -> {
      case dict.get(state.drinks, updated.id) {
        Ok(_) -> {
          let new_drinks = dict.insert(state.drinks, updated.id, updated)
          process.send(reply, Ok(updated))
          actor.continue(State(..state, drinks: new_drinks))
        }
        Error(Nil) -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
    }

    DeleteDrink(id, reply) -> {
      case dict.get(state.drinks, id) {
        Ok(_) -> {
          let new_drinks = dict.delete(state.drinks, id)
          process.send(reply, Ok(Nil))
          actor.continue(State(..state, drinks: new_drinks))
        }
        Error(Nil) -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
    }
  }
}

pub fn list_drinks(store: DrinkStore, store_id: String) -> List(Drink) {
  process.call(store.subject, 5000, ListDrinks(store_id, _))
}

pub fn get_drink(store: DrinkStore, id: String) -> Result(Drink, Nil) {
  process.call(store.subject, 5000, GetDrink(id, _))
}

pub fn create_drink(
  store: DrinkStore,
  store_id: String,
  name: String,
  description: String,
  price_cents: Int,
  category: String,
  available: Bool,
) -> Drink {
  process.call(
    store.subject,
    5000,
    CreateDrink(store_id, name, description, price_cents, category, available, _),
  )
}

pub fn update_drink(store: DrinkStore, drink: Drink) -> Result(Drink, Nil) {
  process.call(store.subject, 5000, UpdateDrink(drink, _))
}

pub fn delete_drink(store: DrinkStore, id: String) -> Result(Nil, Nil) {
  process.call(store.subject, 5000, DeleteDrink(id, _))
}
