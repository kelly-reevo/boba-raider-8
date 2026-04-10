import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import domain/drink.{type DrinkWithDetails, type RatingAxes, DrinkWithDetails, RatingAxes, StoreSummary}

/// Rating record for aggregation
pub type Rating {
  Rating(
    id: String,
    drink_id: String,
    overall: Option(Float),
    sweetness: Option(Float),
    texture: Option(Float),
    tea_strength: Option(Float),
  )
}

/// Raw drink record from storage
pub type DrinkRecord {
  DrinkRecord(
    id: String,
    store_id: String,
    name: String,
    tea_type: String,
    price: Option(Float),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
    created_at: String,
  )
}

/// Store record for joining
pub type StoreRecord {
  StoreRecord(
    id: String,
    name: String,
    address: String,
  )
}

/// In-memory store state (simplified pattern - real DB would be persistent)
pub opaque type Store {
  Store(
    drinks: Dict(String, DrinkRecord),
    ratings: List(Rating),
    stores: Dict(String, StoreRecord),
  )
}

/// Create empty store
pub fn new_store() -> Store {
  Store(
    drinks: dict.new(),
    ratings: [],
    stores: dict.new(),
  )
}

/// Get drink by ID with full details and aggregated ratings
/// Returns None if drink or store not found
pub fn get_drink_by_id(store: Store, drink_id: String) -> Option(DrinkWithDetails) {
  // Look up drink
  case dict.get(store.drinks, drink_id) {
    Error(_) -> None
    Ok(drink_rec) -> {
      // Look up store
      case dict.get(store.stores, drink_rec.store_id) {
        Error(_) -> None
        Ok(store_rec) -> {
          // Get all ratings for this drink and aggregate
          let drink_ratings = list.filter(store.ratings, fn(r) { r.drink_id == drink_id })
          let avg_ratings = calculate_average_ratings(drink_ratings)

          Some(DrinkWithDetails(
            id: drink_rec.id,
            store_id: drink_rec.store_id,
            name: drink_rec.name,
            tea_type: drink_rec.tea_type,
            price: drink_rec.price,
            description: drink_rec.description,
            image_url: drink_rec.image_url,
            is_signature: drink_rec.is_signature,
            created_at: drink_rec.created_at,
            average_rating: avg_ratings,
            store: StoreSummary(
              id: store_rec.id,
              name: store_rec.name,
              address: store_rec.address,
            ),
          ))
        }
      }
    }
  }
}

// Internal accumulator type for averaging
type RatingTotals {
  RatingTotals(
    total_overall: Float,
    total_sweetness: Float,
    total_texture: Float,
    total_tea_strength: Float,
    count_overall: Int,
    count_sweetness: Int,
    count_texture: Int,
    count_tea_strength: Int,
  )
}

/// Calculate average ratings across all axes
fn calculate_average_ratings(ratings: List(Rating)) -> RatingAxes {
  case ratings {
    [] -> RatingAxes(None, None, None, None)
    _ -> {
      let totals = RatingTotals(0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0)
      let final = list.fold(ratings, totals, accumulate_rating)

      RatingAxes(
        overall: calculate_avg(final.total_overall, final.count_overall),
        sweetness: calculate_avg(final.total_sweetness, final.count_sweetness),
        texture: calculate_avg(final.total_texture, final.count_texture),
        tea_strength: calculate_avg(final.total_tea_strength, final.count_tea_strength),
      )
    }
  }
}

fn accumulate_rating(totals: RatingTotals, rating: Rating) -> RatingTotals {
  RatingTotals(
    total_overall: totals.total_overall +. option.unwrap(rating.overall, 0.0),
    total_sweetness: totals.total_sweetness +. option.unwrap(rating.sweetness, 0.0),
    total_texture: totals.total_texture +. option.unwrap(rating.texture, 0.0),
    total_tea_strength: totals.total_tea_strength +. option.unwrap(rating.tea_strength, 0.0),
    count_overall: totals.count_overall + case rating.overall {
      Some(_) -> 1
      None -> 0
    },
    count_sweetness: totals.count_sweetness + case rating.sweetness {
      Some(_) -> 1
      None -> 0
    },
    count_texture: totals.count_texture + case rating.texture {
      Some(_) -> 1
      None -> 0
    },
    count_tea_strength: totals.count_tea_strength + case rating.tea_strength {
      Some(_) -> 1
      None -> 0
    },
  )
}

fn calculate_avg(total: Float, count: Int) -> Option(Float) {
  case count {
    0 -> None
    _ -> Some(total /. int.to_float(count))
  }
}

// Store mutation functions (for use by other units that populate data)

/// Insert a drink into the store
pub fn insert_drink(store: Store, drink: DrinkRecord) -> Store {
  Store(
    ..store,
    drinks: dict.insert(store.drinks, drink.id, drink),
  )
}

/// Insert a store into the store
pub fn insert_store(store: Store, s: StoreRecord) -> Store {
  Store(
    ..store,
    stores: dict.insert(store.stores, s.id, s),
  )
}

/// Insert a rating into the store
pub fn insert_rating(store: Store, rating: Rating) -> Store {
  Store(
    ..store,
    ratings: [rating, ..store.ratings],
  )
}
