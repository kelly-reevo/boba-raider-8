/// API effects for the frontend

import frontend/msg.{type Msg, EditStoreMsg}
import gleam/dynamic
import gleam/json
import lustre/effect.{type Effect}
import shared.{type Store, type StoreInput, type User, type AppError}

// API base URL
const api_base = "/api"

/// Fetch a single store by ID
pub fn fetch_store(store_id: String) -> Effect(Msg) {
  // In real implementation, uses lustre_http.get
  // For now, placeholder that returns no effect
  let _url = api_base <> "/stores/" <> store_id
  effect.none()
}

/// Update a store via PATCH request
pub fn update_store(store_id: String, input: StoreInput) -> Effect(Msg) {
  // In real implementation, uses lustre_http.patch
  let _url = api_base <> "/stores/" <> store_id
  let _body = store_input_to_json(input)
  effect.none()
}

/// Fetch current user for authorization check
pub fn fetch_current_user() -> Effect(Msg) {
  // In real implementation, uses lustre_http.get
  let _url = api_base <> "/me"
  effect.none()
}

// JSON encoder for store input
fn store_input_to_json(input: StoreInput) -> String {
  json.object([
    #("name", json.string(input.name)),
    #("description", json.string(input.description)),
    #("address", json.string(input.address)),
    #("phone", json.string(input.phone)),
    #("email", json.string(input.email)),
  ])
  |> json.to_string()
}
