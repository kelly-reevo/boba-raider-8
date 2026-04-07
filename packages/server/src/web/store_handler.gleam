import gleam/dynamic/decode
import gleam/json
import user_auth
import store
import store_repo.{type StoreRepo}
import web/server.{type Request, type Response}

pub fn handle_create(request: Request, repo: StoreRepo) -> Response {
  case user_auth.get_user_id(request) {
    Error(err) -> error_response(401, err)
    Ok(owner_id) ->
      case decode_store_input(request.body) {
        Error(err) -> error_response(400, err)
        Ok(input) -> {
          let created =
            store_repo.create(repo, input.name, input.address, input.phone, owner_id)
          server.json_response(
            201,
            store.store_to_json(created) |> json.to_string,
          )
        }
      }
  }
}

pub fn handle_list(request: Request, repo: StoreRepo) -> Response {
  case user_auth.get_user_id(request) {
    Error(err) -> error_response(401, err)
    Ok(owner_id) -> {
      let stores = store_repo.list_by_owner(repo, owner_id)
      server.json_response(
        200,
        store.store_list_to_json(stores) |> json.to_string,
      )
    }
  }
}

pub fn handle_get(request: Request, repo: StoreRepo, id: String) -> Response {
  case user_auth.get_user_id(request) {
    Error(err) -> error_response(401, err)
    Ok(owner_id) ->
      case store_repo.get_by_id(repo, id) {
        Ok(s) if s.owner_id == owner_id ->
          server.json_response(200, store.store_to_json(s) |> json.to_string)
        Ok(_) -> error_response(403, "Forbidden")
        Error(_) -> error_response(404, "Store not found")
      }
  }
}

pub fn handle_update(
  request: Request,
  repo: StoreRepo,
  id: String,
) -> Response {
  case user_auth.get_user_id(request) {
    Error(err) -> error_response(401, err)
    Ok(owner_id) ->
      case decode_store_input(request.body) {
        Error(err) -> error_response(400, err)
        Ok(input) ->
          case
            store_repo.update(repo, id, input.name, input.address, input.phone, owner_id)
          {
            Ok(updated) ->
              server.json_response(
                200,
                store.store_to_json(updated) |> json.to_string,
              )
            Error("Forbidden") -> error_response(403, "Forbidden")
            Error("Not found") -> error_response(404, "Store not found")
            Error(err) -> error_response(500, err)
          }
      }
  }
}

pub fn handle_delete(
  request: Request,
  repo: StoreRepo,
  id: String,
) -> Response {
  case user_auth.get_user_id(request) {
    Error(err) -> error_response(401, err)
    Ok(owner_id) ->
      case store_repo.delete(repo, id, owner_id) {
        Ok(_) -> server.json_response(204, "")
        Error("Forbidden") -> error_response(403, "Forbidden")
        Error("Not found") -> error_response(404, "Store not found")
        Error(err) -> error_response(500, err)
      }
  }
}

type StoreInput {
  StoreInput(name: String, address: String, phone: String)
}

fn decode_store_input(body: String) -> Result(StoreInput, String) {
  let decoder = {
    use name <- decode.field("name", decode.string)
    use address <- decode.field("address", decode.string)
    use phone <- decode.field("phone", decode.string)
    decode.success(StoreInput(name:, address:, phone:))
  }
  case json.parse(body, decoder) {
    Ok(input) -> Ok(input)
    Error(_) -> Error("Invalid JSON: requires name, address, phone fields")
  }
}

fn error_response(status: Int, message: String) -> Response {
  server.json_response(
    status,
    json.object([#("error", json.string(message))]) |> json.to_string,
  )
}
