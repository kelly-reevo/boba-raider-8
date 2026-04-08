import auth/user_store.{type UserStore}
import drink_store.{type DrinkStore}
import gleam/json
import gleam/string
import store_repo.{type StoreRepo}
import web/auth_handlers
import web/drinks
import web/server.{type Request, type Response}
import web/static
import web/store_handler

pub fn make_handler(
  user_store: UserStore,
  drink_store: DrinkStore,
  store_repo: StoreRepo,
  jwt_secret: String,
) -> fn(Request) -> Response {
  fn(request: Request) {
    route(request, user_store, drink_store, store_repo, jwt_secret)
  }
}

fn route(
  request: Request,
  user_store: UserStore,
  drink_store: DrinkStore,
  store_repo: StoreRepo,
  jwt_secret: String,
) -> Response {
  let segments = string.split(request.path, "/")
  case request.method, segments {
    "GET", ["", ""] | "GET", [""] -> static.serve_index()
    "GET", ["", "health"] -> health_handler()
    "GET", ["", "api", "health"] -> health_handler()

    // Auth endpoints
    "POST", ["", "api", "auth", "register"] ->
      auth_handlers.handle_register(request, user_store, jwt_secret)
    "POST", ["", "api", "auth", "login"] ->
      auth_handlers.handle_login(request, user_store, jwt_secret)
    "GET", ["", "api", "auth", "me"] ->
      auth_handlers.handle_me(request, user_store, jwt_secret)

    // Store endpoints
    "POST", ["", "api", "stores"] ->
      store_handler.handle_create(request, store_repo)
    "GET", ["", "api", "stores"] ->
      store_handler.handle_list(request, store_repo)
    "GET", ["", "api", "stores", store_id] ->
      store_handler.handle_get(request, store_repo, store_id)
    "PUT", ["", "api", "stores", store_id] ->
      store_handler.handle_update(request, store_repo, store_id)
    "DELETE", ["", "api", "stores", store_id] ->
      store_handler.handle_delete(request, store_repo, store_id)

    // Drink endpoints: /api/stores/:store_id/drinks
    "GET", ["", "api", "stores", store_id, "drinks"] ->
      drinks.list_drinks(request, drink_store, store_id)
    "POST", ["", "api", "stores", store_id, "drinks"] ->
      drinks.create_drink(request, drink_store, store_id)

    // Drink endpoints: /api/stores/:store_id/drinks/:drink_id
    "GET", ["", "api", "stores", _, "drinks", drink_id] ->
      drinks.get_drink(request, drink_store, drink_id)
    "PUT", ["", "api", "stores", store_id, "drinks", drink_id] ->
      drinks.update_drink(request, drink_store, store_id, drink_id)
    "DELETE", ["", "api", "stores", _, "drinks", drink_id] ->
      drinks.delete_drink(request, drink_store, drink_id)

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
