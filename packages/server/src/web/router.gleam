import drink_store.{type DrinkStore}
import gleam/json
import gleam/string
import rating_service.{type RatingService}
import services/drink_service
import web/server.{type Request, type Response, Response}
import web/static

pub fn make_handler(
  drink_store_ref: DrinkStore,
  rating_service_ref: RatingService,
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, drink_store_ref, rating_service_ref) }
}

fn route(
  request: Request,
  drink_store_ref: DrinkStore,
  rating_service_ref: RatingService,
) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "DELETE", path -> route_delete(path, drink_store_ref, rating_service_ref)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn route_delete(
  path: String,
  drink_store_ref: DrinkStore,
  rating_service_ref: RatingService,
) -> Response {
  // Parse path to extract drink ID for /api/drinks/:id pattern
  case string.split(path, "/") {
    ["", "api", "drinks", drink_id] -> {
      delete_drink_handler(drink_store_ref, rating_service_ref, drink_id)
    }
    _ -> not_found()
  }
}

fn delete_drink_handler(
  drink_store_ref: DrinkStore,
  rating_service_ref: RatingService,
  drink_id: String,
) -> Response {
  // Handle empty drink ID
  case string.length(drink_id) > 0 {
    False -> not_found()
    True -> {
      case
        drink_service.delete_drink(
          drink_store_ref,
          rating_service_ref,
          drink_id,
        )
      {
        Ok(_) -> no_content()
        Error(drink_service.NotFoundError(_)) -> not_found()
        Error(drink_service.ValidationError(_)) -> bad_request()
        Error(drink_service.InternalError(_)) -> server_error()
      }
    }
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
    |> json.to_string,
  )
}

fn no_content() -> Response {
  Response(status: 204, headers: server.empty_headers(), body: "")
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
    |> json.to_string,
  )
}

fn bad_request() -> Response {
  server.json_response(
    400,
    json.object([#("error", json.string("Bad request"))])
    |> json.to_string,
  )
}

fn server_error() -> Response {
  server.json_response(
    500,
    json.object([#("error", json.string("Internal server error"))])
    |> json.to_string,
  )
}
