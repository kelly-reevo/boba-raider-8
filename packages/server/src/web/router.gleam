import drink_store.{type DrinkStore}
import gleam/json
import gleam/string
import web/drinks
import web/server.{type Request, type Response}
import web/static

pub fn make_handler(store: DrinkStore) -> fn(Request) -> Response {
  fn(request: Request) { route(request, store) }
}

fn route(request: Request, store: DrinkStore) -> Response {
  let segments = string.split(request.path, "/")
  case request.method, segments {
    "GET", ["", ""] | "GET", [""] -> static.serve_index()
    "GET", ["", "health"] -> health_handler()
    "GET", ["", "api", "health"] -> health_handler()

    // Drink endpoints: /api/stores/:store_id/drinks
    "GET", ["", "api", "stores", store_id, "drinks"] ->
      drinks.list_drinks(request, store, store_id)
    "POST", ["", "api", "stores", store_id, "drinks"] ->
      drinks.create_drink(request, store, store_id)

    // Drink endpoints: /api/stores/:store_id/drinks/:drink_id
    "GET", ["", "api", "stores", _, "drinks", drink_id] ->
      drinks.get_drink(request, store, drink_id)
    "PUT", ["", "api", "stores", store_id, "drinks", drink_id] ->
      drinks.update_drink(request, store, store_id, drink_id)
    "DELETE", ["", "api", "stores", _, "drinks", drink_id] ->
      drinks.delete_drink(request, store, drink_id)

    "GET", _ ->
      case string.starts_with(request.path, "/static/") {
        True -> static.serve(request.path)
        False -> not_found()
      }
    _, _ -> not_found()
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
      |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
      |> json.to_string,
  )
}
