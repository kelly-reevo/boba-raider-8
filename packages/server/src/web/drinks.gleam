import drink.{Drink}
import drink_store.{type DrinkStore}
import gleam/json
import web/auth
import web/server.{type Request, type Response}

pub fn list_drinks(
  request: Request,
  store: DrinkStore,
  store_id: String,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) -> unauthorized()
    Ok(_) -> {
      let drinks = drink_store.list_drinks(store, store_id)
      server.json_response(
        200,
        json.object([#("drinks", drink.list_to_json(drinks))])
          |> json.to_string,
      )
    }
  }
}

pub fn get_drink(
  request: Request,
  store: DrinkStore,
  drink_id: String,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) -> unauthorized()
    Ok(_) ->
      case drink_store.get_drink(store, drink_id) {
        Ok(d) ->
          server.json_response(200, drink.to_json(d) |> json.to_string)
        Error(_) -> not_found("Drink not found")
      }
  }
}

pub fn create_drink(
  request: Request,
  store: DrinkStore,
  store_id: String,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) -> unauthorized()
    Ok(_) ->
      case json.parse(request.body, drink.decoder()) {
        Ok(input) -> {
          let created =
            drink_store.create_drink(
              store,
              store_id,
              input.name,
              input.description,
              input.price_cents,
              input.category,
              input.available,
            )
          server.json_response(201, drink.to_json(created) |> json.to_string)
        }
        Error(_) -> bad_request("Invalid drink data")
      }
  }
}

pub fn update_drink(
  request: Request,
  store: DrinkStore,
  store_id: String,
  drink_id: String,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) -> unauthorized()
    Ok(_) ->
      case json.parse(request.body, drink.decoder()) {
        Ok(input) -> {
          let updated =
            Drink(
              ..input,
              id: drink_id,
              store_id: store_id,
            )
          case drink_store.update_drink(store, updated) {
            Ok(d) ->
              server.json_response(200, drink.to_json(d) |> json.to_string)
            Error(_) -> not_found("Drink not found")
          }
        }
        Error(_) -> bad_request("Invalid drink data")
      }
  }
}

pub fn delete_drink(
  request: Request,
  store: DrinkStore,
  drink_id: String,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) -> unauthorized()
    Ok(_) ->
      case drink_store.delete_drink(store, drink_id) {
        Ok(_) ->
          server.json_response(
            200,
            json.object([#("deleted", json.bool(True))])
              |> json.to_string,
          )
        Error(_) -> not_found("Drink not found")
      }
  }
}

fn unauthorized() -> Response {
  server.json_response(
    401,
    json.object([#("error", json.string("Unauthorized"))])
      |> json.to_string,
  )
}

fn not_found(msg: String) -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string(msg))])
      |> json.to_string,
  )
}

fn bad_request(msg: String) -> Response {
  server.json_response(
    400,
    json.object([#("error", json.string(msg))])
      |> json.to_string,
  )
}
