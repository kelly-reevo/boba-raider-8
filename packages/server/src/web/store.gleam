/// Store and drink domain types and data access

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/string
import shared.{type AppError, InvalidInput, NotFound}

// ============== Domain Types ==============

pub type TeaType {
  Black
  Green
  Oolong
  White
  Herbal
  Matcha
  Other
}

pub type Rating {
  Rating(
    overall: Float,
    sweetness: Float,
    texture: Float,
    tea_strength: Float,
  )
}

pub type Drink {
  Drink(
    id: String,
    name: String,
    tea_type: TeaType,
    price: Option(Float),
    image_url: Option(String),
    store_id: String,
    average_rating: Option(Rating),
  )
}

pub type Store {
  Store(
    id: String,
    name: String,
    address: Option(String),
  )
}

pub type SortOption {
  RatingDesc
  RatingAsc
  Name
}

pub type PaginationMeta {
  PaginationMeta(
    total: Int,
    page: Int,
    limit: Int,
    total_pages: Int,
  )
}

// ============== Static Data Store ==============

fn stores() -> List(Store) {
  [
    Store(id: "store-1", name: "Boba Paradise", address: Some("123 Main St")),
    Store(id: "store-2", name: "Tea Haven", address: Some("456 Oak Ave")),
    Store(id: "store-3", name: "Milk Tea Lab", address: None),
  ]
}

fn drinks() -> List(Drink) {
  [
    Drink(
      id: "drink-1",
      name: "Classic Milk Tea",
      tea_type: Black,
      price: Some(5.50),
      image_url: Some("/images/classic.jpg"),
      store_id: "store-1",
      average_rating: Some(Rating(4.5, 4.0, 4.5, 4.0)),
    ),
    Drink(
      id: "drink-2",
      name: "Jasmine Green Tea",
      tea_type: Green,
      price: Some(4.75),
      image_url: None,
      store_id: "store-1",
      average_rating: Some(Rating(4.2, 4.5, 3.8, 3.9)),
    ),
    Drink(
      id: "drink-3",
      name: "Oolong Milk Tea",
      tea_type: Oolong,
      price: Some(6.00),
      image_url: Some("/images/oolong.jpg"),
      store_id: "store-1",
      average_rating: None,
    ),
    Drink(
      id: "drink-4",
      name: "Matcha Latte",
      tea_type: Matcha,
      price: Some(6.50),
      image_url: Some("/images/matcha.jpg"),
      store_id: "store-2",
      average_rating: Some(Rating(4.8, 4.2, 4.9, 4.5)),
    ),
    Drink(
      id: "drink-5",
      name: "Honey Black Tea",
      tea_type: Black,
      price: Some(5.25),
      image_url: None,
      store_id: "store-2",
      average_rating: Some(Rating(4.0, 5.0, 3.5, 4.0)),
    ),
    Drink(
      id: "drink-6",
      name: "Herbal Mint Tea",
      tea_type: Herbal,
      price: Some(4.50),
      image_url: Some("/images/herbal.jpg"),
      store_id: "store-3",
      average_rating: Some(Rating(3.8, 3.5, 4.0, 2.5)),
    ),
  ]
}

// ============== Helper Functions ==============

pub fn tea_type_from_string(s: String) -> Result(TeaType, AppError) {
  case string.lowercase(s) {
    "black" -> Ok(Black)
    "green" -> Ok(Green)
    "oolong" -> Ok(Oolong)
    "white" -> Ok(White)
    "herbal" -> Ok(Herbal)
    "matcha" -> Ok(Matcha)
    "other" -> Ok(Other)
    _ -> Error(InvalidInput("Invalid tea_type: " <> s))
  }
}

pub fn sort_option_from_string(s: String) -> Result(SortOption, AppError) {
  case s {
    "rating_desc" -> Ok(RatingDesc)
    "rating_asc" -> Ok(RatingAsc)
    "name" -> Ok(Name)
    _ -> Error(InvalidInput("Invalid sort: " <> s))
  }
}

pub fn default_sort() -> SortOption {
  RatingDesc
}

// ============== Data Access ==============

pub fn get_store(store_id: String) -> Result(Store, AppError) {
  case list.find(stores(), fn(s) { s.id == store_id }) {
    Ok(store) -> Ok(store)
    Error(_) -> Error(NotFound("Store not found"))
  }
}

pub fn list_drinks(
  store_id: String,
  tea_type_filter: Option(TeaType),
  sort: SortOption,
  page: Int,
  limit: Int,
) -> Result(#(List(Drink), PaginationMeta), AppError) {
  // Verify store exists
  case get_store(store_id) {
    Error(e) -> Error(e)
    Ok(_) -> {
      let all_drinks = drinks()
        |> list.filter(fn(d) { d.store_id == store_id })
        |> apply_tea_type_filter(tea_type_filter)
        |> apply_sort(sort)

      let total = list.length(all_drinks)
      let total_pages = case total {
        0 -> 0
        n -> { n + limit - 1 } / limit
      }

      let paginated = all_drinks
        |> list.drop({ page - 1 } * limit)
        |> list.take(limit)

      let meta = PaginationMeta(
        total: total,
        page: page,
        limit: limit,
        total_pages: total_pages,
      )

      Ok(#(paginated, meta))
    }
  }
}

fn apply_tea_type_filter(
  drinks: List(Drink),
  filter: Option(TeaType),
) -> List(Drink) {
  case filter {
    None -> drinks
    Some(tea_type) -> list.filter(drinks, fn(d) { d.tea_type == tea_type })
  }
}

fn apply_sort(drinks: List(Drink), sort: SortOption) -> List(Drink) {
  let compare_fn = case sort {
    RatingDesc -> compare_by_rating_desc
    RatingAsc -> compare_by_rating_asc
    Name -> compare_by_name
  }
  list.sort(drinks, compare_fn)
}

fn compare_by_rating_desc(a: Drink, b: Drink) -> Order {
  let a_rating = option.map(a.average_rating, fn(r) { r.overall }) |> option.unwrap(0.0)
  let b_rating = option.map(b.average_rating, fn(r) { r.overall }) |> option.unwrap(0.0)
  case a_rating >. b_rating {
    True -> order.Lt
    False -> case a_rating <. b_rating {
      True -> order.Gt
      False -> order.Eq
    }
  }
}

fn compare_by_rating_asc(a: Drink, b: Drink) -> Order {
  let a_rating = option.map(a.average_rating, fn(r) { r.overall }) |> option.unwrap(0.0)
  let b_rating = option.map(b.average_rating, fn(r) { r.overall }) |> option.unwrap(0.0)
  case a_rating <. b_rating {
    True -> order.Lt
    False -> case a_rating >. b_rating {
      True -> order.Gt
      False -> order.Eq
    }
  }
}

fn compare_by_name(a: Drink, b: Drink) -> Order {
  string.compare(a.name, b.name)
}

// ============== JSON Serialization ==============

pub fn tea_type_to_string(tea_type: TeaType) -> String {
  case tea_type {
    Black -> "black"
    Green -> "green"
    Oolong -> "oolong"
    White -> "white"
    Herbal -> "herbal"
    Matcha -> "matcha"
    Other -> "other"
  }
}
