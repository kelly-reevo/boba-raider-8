/// In-memory CRUD store for drinks

import gleam/dict.{type Dict}
import gleam/list
import shared.{type AppError, InvalidInput, NotFound}
import drink.{type Drink, Drink}

pub type DrinkStore =
  Dict(String, Drink)

pub fn new() -> DrinkStore {
  dict.new()
}

pub fn create(
  store: DrinkStore,
  drink: Drink,
) -> Result(#(DrinkStore, Drink), AppError) {
  case drink.id, drink.name, drink.store_id {
    "", _, _ -> Error(InvalidInput("drink id is required"))
    _, "", _ -> Error(InvalidInput("drink name is required"))
    _, _, "" -> Error(InvalidInput("drink store_id is required"))
    _, _, _ ->
      case dict.get(store, drink.id) {
        Ok(_) -> Error(InvalidInput("drink already exists: " <> drink.id))
        Error(_) -> Ok(#(dict.insert(store, drink.id, drink), drink))
      }
  }
}

pub fn get(store: DrinkStore, id: String) -> Result(Drink, AppError) {
  dict.get(store, id)
  |> map_not_found(id)
}

pub fn list_all(store: DrinkStore) -> List(Drink) {
  dict.values(store)
}

pub fn list_by_store(store: DrinkStore, store_id: String) -> List(Drink) {
  dict.values(store)
  |> list.filter(fn(d) { d.store_id == store_id })
}

pub fn update(
  store: DrinkStore,
  id: String,
  name: String,
  description: String,
  store_id: String,
) -> Result(#(DrinkStore, Drink), AppError) {
  case dict.get(store, id) {
    Error(_) -> Error(NotFound("drink not found: " <> id))
    Ok(_) -> {
      let updated = Drink(id: id, name: name, description: description, store_id: store_id)
      Ok(#(dict.insert(store, id, updated), updated))
    }
  }
}

pub fn delete(
  store: DrinkStore,
  id: String,
) -> Result(DrinkStore, AppError) {
  case dict.get(store, id) {
    Error(_) -> Error(NotFound("drink not found: " <> id))
    Ok(_) -> Ok(dict.delete(store, id))
  }
}

fn map_not_found(
  result: Result(a, Nil),
  id: String,
) -> Result(a, AppError) {
  case result {
    Ok(val) -> Ok(val)
    Error(_) -> Error(NotFound("drink not found: " <> id))
  }
}
