import boba_store.{type BobaStore}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import web/server.{type Request, type Response, json_response}

// Drink creation input from HTTP request
pub type DrinkInput {
  DrinkInput(
    store_id: Int,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

// Validation error type
pub type ValidationError {
  ValidationError(field: String, message: String)
}

// Drink response matching boundary contract
pub type DrinkResponse {
  DrinkResponse(
    id: Int,
    store_id: Int,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    created_at: String,
  )
}

// In-memory drink storage (simple counter-based ID system)
pub type DrinkState {
  DrinkState(
    drinks: Dict(Int, DrinkResponse),
    next_id: Int,
  )
}

// Store wrapper that combines both stores
pub type StoreWrapper {
  StoreWrapper(boba_store: BobaStore, drink_state: DrinkState)
}

/// Create a handler function that routes requests
pub fn make_handler(boba_store: BobaStore) -> fn(Request) -> Response {
  let drink_state = DrinkState(drinks: dict.new(), next_id: 1)
  let wrapper = StoreWrapper(boba_store:, drink_state:)

  fn(request: Request) { route(wrapper, request) }
}

/// Main router
fn route(wrapper: StoreWrapper, request: Request) -> Response {
  case request.method, request.path {
    "POST", "/api/drinks" -> create_drink_handler(wrapper, request)
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

/// Handle GET requests
fn route_get(path: String) -> Response {
  case path {
    "/" -> json_response(200, "{\"status\":\"ok\"}")
    _ -> not_found()
  }
}

/// Health check handler
fn health_handler() -> Response {
  json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

/// 404 handler
fn not_found() -> Response {
  json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

/// Parse drink input from JSON
fn parse_drink_input(body: String) -> Result(DrinkInput, List(ValidationError)) {
  let decoder = {
    // Required fields with defaults for validation handling
    use store_id <- decode.optional_field("store_id", 0, decode.int)
    use name <- decode.optional_field("name", "", decode.string)
    // Optional fields
    use description <- decode.optional_field("description", None, decode.optional(decode.string))
    use base_tea_type <- decode.optional_field("base_tea_type", None, decode.optional(decode.string))
    use price <- decode.optional_field("price", None, decode.optional(decode.float))

    decode.success(DrinkInput(
      store_id: store_id,
      name: name,
      description: description,
      base_tea_type: base_tea_type,
      price: price,
    ))
  }

  case json.parse(from: body, using: decoder) {
    Ok(input) -> Ok(input)
    Error(_) -> Error([ValidationError("body", "Invalid JSON")])
  }
}

/// Validate drink input
fn validate_drink_input(input: DrinkInput) -> List(ValidationError) {
  let store_id_errors = validate_store_id(input.store_id)
  let name_errors = validate_name(input.name)

  list.flatten([store_id_errors, name_errors])
}

fn validate_store_id(store_id: Int) -> List(ValidationError) {
  case store_id > 0 {
    True -> []
    False -> [ValidationError("store_id", "Store ID must be a positive integer")]
  }
}

fn validate_name(name: String) -> List(ValidationError) {
  let trimmed = string.trim(name)
  let length = string.length(trimmed)

  case string.is_empty(trimmed), length < 2 {
    True, _ -> [ValidationError("name", "Name is required")]
    False, True -> [ValidationError("name", "Name must be at least 2 characters")]
    False, False -> []
  }
}

/// Convert validation errors to JSON
fn validation_errors_to_json(errors: List(ValidationError)) -> String {
  let error_objects = list.map(errors, fn(error) {
    json.object([
      #("field", json.string(error.field)),
      #("message", json.string(error.message)),
    ])
  })

  json.object([
    #("error", json.string("Validation failed")),
    #("errors", json.array(error_objects, of: fn(x) { x })),
  ])
  |> json.to_string
}

/// Convert drink response to JSON
fn drink_response_to_json(drink: DrinkResponse) -> String {
  let base_fields = [
    #("id", json.int(drink.id)),
    #("store_id", json.int(drink.store_id)),
    #("name", json.string(drink.name)),
    #("created_at", json.string(drink.created_at)),
  ]

  let fields_with_optional = case drink.description {
    Some(d) -> [#("description", json.string(d)), ..base_fields]
    None -> base_fields
  }

  let fields_with_tea = case drink.base_tea_type {
    Some(t) -> [#("base_tea_type", json.string(t)), ..fields_with_optional]
    None -> fields_with_optional
  }

  let all_fields = case drink.price {
    Some(p) -> [#("price", json.float(p)), ..fields_with_tea]
    None -> fields_with_tea
  }

  json.object(all_fields)
  |> json.to_string
}

/// Create drink handler
fn create_drink_handler(wrapper: StoreWrapper, request: Request) -> Response {
  // Step 1: Parse the request body
  let parsed = parse_drink_input(request.body)

  case parsed {
    Error(parse_errors) -> {
      // JSON parse error
      json_response(422, validation_errors_to_json(parse_errors))
    }

    Ok(input) -> {
      // Step 2: Validate input
      let validation_errors = validate_drink_input(input)

      case validation_errors {
        [] -> {
          // Step 3: Check if store exists
          let store_exists = boba_store.check_store_exists(
            wrapper.boba_store,
            int.to_string(input.store_id),
          )

          case store_exists {
            False -> {
              // Store not found - return 404
              json_response(
                404,
                json.object([#("message", json.string("Store not found"))])
                |> json.to_string,
              )
            }

            True -> {
              // Step 4: Create the drink
              let drink = create_drink_in_memory(wrapper, input)
              json_response(201, drink_response_to_json(drink))
            }
          }
        }

        errors -> {
          // Validation failed - return 422
          json_response(422, validation_errors_to_json(errors))
        }
      }
    }
  }
}

/// Create drink in memory
fn create_drink_in_memory(wrapper: StoreWrapper, input: DrinkInput) -> DrinkResponse {
  // Generate simple ID and timestamp
  let id = wrapper.drink_state.next_id
  let now = current_timestamp()

  DrinkResponse(
    id: id,
    store_id: input.store_id,
    name: input.name,
    description: input.description,
    base_tea_type: input.base_tea_type,
    price: input.price,
    created_at: now,
  )
}

/// Get current timestamp in ISO format
fn current_timestamp() -> String {
  "2026-04-12T00:00:00Z"
}
