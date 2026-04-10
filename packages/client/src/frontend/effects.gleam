/// API effects for the frontend

import frontend/msg.{type Msg}
import gleam/http
import gleam/http/request
import gleam/json
import lustre/effect.{type Effect}
import shared.{type CreateDrinkInput, tea_type_to_string}

/// Upload image file to server
/// Returns the uploaded image URL on success
pub fn upload_image(file_data: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let url = "/api/upload/image"

    let body =
      json.object([#("file", json.string(file_data))])
      |> json.to_string

    let _req =
      request.new()
      |> request.set_method(http.Post)
      |> request.set_host("")
      |> request.set_path(url)
      |> request.set_header("Content-Type", "application/json")
      |> request.set_body(body)

    // Note: Actual HTTP implementation would use lustre_http or browser fetch API
    // This effect dispatches a message - actual HTTP client should be wired here
    let mock_response = msg.ImageUploaded(Ok("/uploads/mock-image.jpg"))
    dispatch(mock_response)
  })
}

/// Create a new drink for a store
pub fn create_drink(store_id: String, input: CreateDrinkInput) -> Effect(Msg) {
  effect.from(fn(_dispatch) {
    let url = "/api/stores/" <> store_id <> "/drinks"

    let _body =
      json.object([
        #("name", json.string(input.name)),
        #("tea_type", json.string(tea_type_to_string(input.tea_type))),
        #("price", json.float(input.price)),
        #("description", json.string(input.description)),
        #("image_url", json.string(input.image_url)),
        #("is_signature", json.bool(input.is_signature)),
      ])
      |> json.to_string

    let _req =
      request.new()
      |> request.set_method(http.Post)
      |> request.set_host("")
      |> request.set_path(url)
      |> request.set_header("Content-Type", "application/json")

    // Note: Actual HTTP implementation should dispatch DrinkCreated result
    // This is a placeholder - integrate with lustre_http or browser fetch
    Nil
  })
}

/// No operation effect
pub fn none() -> Effect(Msg) {
  effect.none()
}
