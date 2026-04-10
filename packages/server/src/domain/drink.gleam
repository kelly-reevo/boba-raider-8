import gleam/json
import gleam/option.{type Option}

/// Rating axes for drink reviews
pub type RatingAxes {
  RatingAxes(
    overall: Option(Float),
    sweetness: Option(Float),
    texture: Option(Float),
    tea_strength: Option(Float),
  )
}

/// Store information nested in drink response
pub type StoreSummary {
  StoreSummary(
    id: String,
    name: String,
    address: String,
  )
}

/// Full drink details with aggregated ratings
pub type DrinkWithDetails {
  DrinkWithDetails(
    id: String,
    store_id: String,
    name: String,
    tea_type: String,
    price: Option(Float),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
    created_at: String,
    average_rating: RatingAxes,
    store: StoreSummary,
  )
}

/// Encode rating axes to JSON (null for missing ratings)
fn encode_rating_axes(axes: RatingAxes) -> json.Json {
  json.object([
    #("overall", option.map(axes.overall, json.float) |> option.unwrap(json.null())),
    #("sweetness", option.map(axes.sweetness, json.float) |> option.unwrap(json.null())),
    #("texture", option.map(axes.texture, json.float) |> option.unwrap(json.null())),
    #("tea_strength", option.map(axes.tea_strength, json.float) |> option.unwrap(json.null())),
  ])
}

/// Encode store summary to JSON
fn encode_store_summary(store: StoreSummary) -> json.Json {
  json.object([
    #("id", json.string(store.id)),
    #("name", json.string(store.name)),
    #("address", json.string(store.address)),
  ])
}

/// Encode drink with details to JSON
pub fn encode_drink_with_details(drink: DrinkWithDetails) -> json.Json {
  json.object([
    #("id", json.string(drink.id)),
    #("store_id", json.string(drink.store_id)),
    #("name", json.string(drink.name)),
    #("tea_type", json.string(drink.tea_type)),
    #("price", option.map(drink.price, json.float) |> option.unwrap(json.null())),
    #("description", option.map(drink.description, json.string) |> option.unwrap(json.null())),
    #("image_url", option.map(drink.image_url, json.string) |> option.unwrap(json.null())),
    #("is_signature", json.bool(drink.is_signature)),
    #("created_at", json.string(drink.created_at)),
    #("average_rating", encode_rating_axes(drink.average_rating)),
    #("store", encode_store_summary(drink.store)),
  ])
}
