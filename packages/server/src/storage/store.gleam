/// In-memory storage using dictionaries
/// Simple storage for drinks and ratings

import domain/drink.{type Drink, type DrinkId}
import domain/rating.{type Rating, type RatingId}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/result

// In-memory storage using dictionaries
pub type Store {
  Store(
    drinks: Dict(DrinkId, Drink),
    ratings: Dict(RatingId, Rating),
    drink_ratings_index: Dict(DrinkId, List(RatingId)),
  )
}

/// Create a new empty store
pub fn new() -> Store {
  Store(drinks: dict.new(), ratings: dict.new(), drink_ratings_index: dict.new())
}

/// Get a drink by ID
pub fn get_drink(store: Store, id: DrinkId) -> Option(Drink) {
  dict.get(store.drinks, id)
  |> option.from_result()
}

/// Insert or update a drink
pub fn put_drink(store: Store, drink: Drink) -> Store {
  Store(
    ..store,
    drinks: dict.insert(store.drinks, drink.id, drink),
  )
}

/// Delete a drink and cascade delete its ratings
pub fn delete_drink(store: Store, id: DrinkId) -> Store {
  // Get rating IDs associated with this drink
  let rating_ids =
    dict.get(store.drink_ratings_index, id)
    |> result.unwrap([])

  // Delete all associated ratings
  let new_ratings =
    list.fold(rating_ids, store.ratings, fn(acc, rating_id) {
      dict.delete(acc, rating_id)
    })

  // Remove drink from index
  let new_index = dict.delete(store.drink_ratings_index, id)

  // Delete the drink itself
  let new_drinks = dict.delete(store.drinks, id)

  Store(drinks: new_drinks, ratings: new_ratings, drink_ratings_index: new_index)
}

/// Insert a rating and update the drink index
pub fn put_rating(store: Store, rating: Rating) -> Store {
  let new_ratings = dict.insert(store.ratings, rating.id, rating)

  // Update the drink -> ratings index
  let existing_ids =
    dict.get(store.drink_ratings_index, rating.drink_id)
    |> result.unwrap([])

  let new_index =
    dict.insert(
      store.drink_ratings_index,
      rating.drink_id,
      [rating.id, ..existing_ids],
    )

  Store(..store, ratings: new_ratings, drink_ratings_index: new_index)
}

/// Get ratings for a specific drink
pub fn get_drink_ratings(store: Store, drink_id: DrinkId) -> List(Rating) {
  let rating_ids =
    dict.get(store.drink_ratings_index, drink_id)
    |> result.unwrap([])

  list.filter_map(rating_ids, fn(id) {
    dict.get(store.ratings, id)
  })
}
