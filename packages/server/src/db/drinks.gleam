import gleam/json.{type Json}
import gleam/option.{type Option}

/// Tea type enum representing different varieties of tea
pub type TeaType {
  Black
  Green
  Oolong
  White
  Herbal
  Milk
  Other
}

/// Drink record representing a boba tea drink
/// Note: Using String for UUIDs and String for price to preserve decimal precision
pub type Drink {
  Drink(
    id: String,
    store_id: String,
    name: String,
    tea_type: TeaType,
    price: Option(String),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Parameters for creating a new drink
pub type CreateDrinkParams {
  CreateDrinkParams(
    store_id: String,
    name: String,
    tea_type: TeaType,
    price: Option(String),
    description: Option(String),
    image_url: Option(String),
    is_signature: Bool,
  )
}

/// Parameters for updating a drink
pub type UpdateDrinkParams {
  UpdateDrinkParams(
    name: Option(String),
    tea_type: Option(TeaType),
    price: Option(String),
    description: Option(String),
    image_url: Option(String),
    is_signature: Option(Bool),
  )
}

/// Convert TeaType to string for database storage
pub fn tea_type_to_string(tea_type: TeaType) -> String {
  case tea_type {
    Black -> "black"
    Green -> "green"
    Oolong -> "oolong"
    White -> "white"
    Herbal -> "herbal"
    Milk -> "milk"
    Other -> "other"
  }
}

/// Parse TeaType from string
pub fn tea_type_from_string(s: String) -> Result(TeaType, Nil) {
  case s {
    "black" -> Ok(Black)
    "green" -> Ok(Green)
    "oolong" -> Ok(Oolong)
    "white" -> Ok(White)
    "herbal" -> Ok(Herbal)
    "milk" -> Ok(Milk)
    "other" -> Ok(Other)
    _ -> Error(Nil)
  }
}

/// Convert TeaType to JSON
pub fn tea_type_to_json(tea_type: TeaType) -> Json {
  json.string(tea_type_to_string(tea_type))
}

/// Drink to JSON encoder
pub fn drink_to_json(drink: Drink) -> Json {
  json.object([
    #("id", json.string(drink.id)),
    #("store_id", json.string(drink.store_id)),
    #("name", json.string(drink.name)),
    #("tea_type", tea_type_to_json(drink.tea_type)),
    #("price", option.map(drink.price, json.string) |> option.unwrap(json.null())),
    #("description", option.map(drink.description, json.string) |> option.unwrap(json.null())),
    #("image_url", option.map(drink.image_url, json.string) |> option.unwrap(json.null())),
    #("is_signature", json.bool(drink.is_signature)),
    #("created_at", json.string(drink.created_at)),
    #("updated_at", json.string(drink.updated_at)),
  ])
}

/// SQL query: Get all drinks for a store
pub const get_by_store_sql = "
  SELECT id, store_id, name, tea_type, price, description, image_url, is_signature, created_at, updated_at
  FROM drinks
  WHERE store_id = $1
  ORDER BY name
"

/// SQL query: Get drink by ID
pub const get_by_id_sql = "
  SELECT id, store_id, name, tea_type, price, description, image_url, is_signature, created_at, updated_at
  FROM drinks
  WHERE id = $1
"

/// SQL query: Get signature drinks for a store
pub const get_signatures_by_store_sql = "
  SELECT id, store_id, name, tea_type, price, description, image_url, is_signature, created_at, updated_at
  FROM drinks
  WHERE store_id = $1 AND is_signature = true
  ORDER BY name
"

/// SQL query: Create new drink
pub const create_sql = "
  INSERT INTO drinks (store_id, name, tea_type, price, description, image_url, is_signature)
  VALUES ($1, $2, $3, $4, $5, $6, $7)
  RETURNING id, store_id, name, tea_type, price, description, image_url, is_signature, created_at, updated_at
"

/// SQL query: Update drink
pub const update_sql = "
  UPDATE drinks
  SET name = COALESCE($2, name),
      tea_type = COALESCE($3, tea_type),
      price = COALESCE($4, price),
      description = COALESCE($5, description),
      image_url = COALESCE($6, image_url),
      is_signature = COALESCE($7, is_signature),
      updated_at = now()
  WHERE id = $1
  RETURNING id, store_id, name, tea_type, price, description, image_url, is_signature, created_at, updated_at
"

/// SQL query: Delete drink
pub const delete_sql = "
  DELETE FROM drinks WHERE id = $1
"
