import counter.{type CounterMsg}
import gleam/dict
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared.{type Priority, type Todo, NotFound, todo_to_json}
import shared/todo_validation
import todo_actor.{type TodoMsg}
import web/context.{type Context}
import wisp

pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  use <- cors_middleware(req)

  case wisp.path_segments(req) {
    [] -> wisp.redirect(to: "/static/index.html")
    ["health"] -> health_handler(req)
    ["api", "health"] -> health_handler(req)
    ["api", "counter"] -> get_counter(req, ctx)
    ["api", "counter", action] -> counter_action(req, ctx, action)
    // Todo endpoints
    ["api", "todos"] -> handle_todos_list_or_create(req, ctx)
    ["api", "todos", id] -> handle_todo_by_id(req, ctx, id)
    _ -> wisp.not_found()
  }
}

fn cors_middleware(
  req: wisp.Request,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  case req.method {
    http.Options ->
      wisp.response(204)
      |> wisp.set_header("access-control-allow-origin", "*")
      |> wisp.set_header("access-control-allow-methods", "GET, POST, PATCH, DELETE, OPTIONS")
      |> wisp.set_header("access-control-allow-headers", "Content-Type")
    _ ->
      next()
      |> wisp.set_header("access-control-allow-origin", "*")
      |> wisp.set_header("access-control-allow-methods", "GET, POST, PATCH, DELETE, OPTIONS")
      |> wisp.set_header("access-control-allow-headers", "Content-Type")
  }
}

fn health_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  json.object([#("status", json.string("ok"))])
  |> json.to_string
  |> wisp.json_response(200)
}

fn get_counter(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  counter.get_count(ctx.counter) |> counter_response
}

fn counter_action(
  req: wisp.Request,
  ctx: Context,
  action: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)
  case action {
    "increment" -> counter.increment(ctx.counter) |> counter_response
    "decrement" -> counter.decrement(ctx.counter) |> counter_response
    "reset" -> counter.reset(ctx.counter) |> counter_response
    _ -> wisp.not_found()
  }
}

fn counter_response(count: Int) -> wisp.Response {
  json.object([#("count", json.int(count))])
  |> json.to_string
  |> wisp.json_response(200)
}

// FFI to read request body as string
@external(erlang, "server_ffi", "read_body_string")
fn read_body_string(req: wisp.Request) -> String

// Todo handlers

fn handle_todos_list_or_create(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> list_todos_handler(req, ctx)
    http.Post -> create_todo_handler(req, ctx)
    http.Options -> wisp.response(204)
    _ -> wisp.method_not_allowed([http.Get, http.Post, http.Options])
  }
}

fn handle_todo_by_id(req: wisp.Request, ctx: Context, id: String) -> wisp.Response {
  case req.method {
    http.Get -> get_todo_handler(req, ctx, id)
    http.Patch -> patch_todo_handler(req, ctx, id)
    http.Delete -> delete_todo_handler(req, ctx, id)
    http.Options -> wisp.response(204)
    _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete, http.Options])
  }
}

fn list_todos_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Parse filter from query string (wisp.get_query returns List(#(String, String)))
  let query_params = wisp.get_query(req)
  let filter = case list.find(query_params, fn(p) { p.0 == "filter" }) {
    Ok(#(_, "active")) -> Some("active")
    Ok(#(_, "completed")) -> Some("completed")
    _ -> None
  }

  let all_todos = todo_actor.get_all_todos(ctx.todo_subject)
  let filtered_todos = case filter {
    Some("active") -> list.filter(all_todos, fn(t) { !t.completed })
    Some("completed") -> list.filter(all_todos, fn(t) { t.completed })
    _ -> all_todos
  }

  json.array(filtered_todos, todo_to_json)
  |> json.to_string
  |> wisp.json_response(200)
}

fn create_todo_handler(req: wisp.Request, ctx: Context) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Read body as string
  let body_string = read_body_string(req)

  // Decoder for create todo request
  let create_decoder = {
    use title <- decode.field("title", decode.optional(decode.string))
    use description <- decode.field("description", decode.optional(decode.string))
    use priority <- decode.field("priority", decode.optional(decode.string))
    decode.success(#(title, description, priority))
  }

  case json.parse(body_string, create_decoder) {
    Ok(#(title_opt, description_opt, priority_opt)) -> {
      let title = option.unwrap(title_opt, "")
      let priority = option.unwrap(priority_opt, "")

      // Validate that priority is not empty
      case priority {
        "" -> {
          json.object([#("errors", json.array(["Priority is required"], json.string))])
          |> json.to_string
          |> wisp.json_response(400)
        }
        _ -> {
          case todo_validation.validate_todo_input(title, description_opt, priority) {
            Ok(validated_input) -> {
              let created_todo = todo_actor.create_todo(
                ctx.todo_subject,
                validated_input.title,
                validated_input.description,
                validated_input.priority,
              )
              todo_to_json(created_todo)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(validation_errors) -> {
              json.object([#("errors", json.array(validation_errors, json.string))])
              |> json.to_string
              |> wisp.json_response(400)
            }
          }
        }
      }
    }
    Error(_) -> {
      json.object([#("errors", json.array(["Invalid JSON"], json.string))])
      |> json.to_string
      |> wisp.json_response(400)
    }
  }
}

fn get_todo_handler(req: wisp.Request, ctx: Context, id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case is_valid_uuid(id) {
    False ->
      json.object([#("error", json.string("not_found"))])
      |> json.to_string
      |> wisp.json_response(404)
    True -> {
      case todo_actor.get_todo(ctx.todo_subject, id) {
        Ok(found_todo) ->
          todo_to_json(found_todo)
          |> json.to_string
          |> wisp.json_response(200)
        Error(NotFound) ->
          json.object([#("error", json.string("not_found"))])
          |> json.to_string
          |> wisp.json_response(404)
        Error(_) ->
          json.object([#("error", json.string("internal_error"))])
          |> json.to_string
          |> wisp.json_response(500)
      }
    }
  }
}

fn patch_todo_handler(req: wisp.Request, ctx: Context, id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Patch)

  // Read body as string
  let body_string = read_body_string(req)

  // Build decoder for optional patch fields
  let patch_decoder = {
    use title_opt <- decode.field("title", decode.optional(decode.string))
    use description_opt <- decode.field("description", decode.optional(decode.string))
    use priority_opt <- decode.field("priority", decode.optional(decode.string))
    use completed_opt <- decode.field("completed", decode.optional(decode.bool))
    decode.success(#(title_opt, description_opt, priority_opt, completed_opt))
  }

  case json.parse(body_string, patch_decoder) {
    Ok(#(title_opt, description_opt, priority_opt, completed_opt)) -> {
      // Convert string priority to Priority type if present
      let parsed_priority = case priority_opt {
        Some(p) -> parse_priority_string(p)
        None -> Ok(None)
      }

      case parsed_priority {
        Ok(priority_value) -> {
          let patch = todo_validation.TodoPatch(
            title: title_opt,
            description: description_opt,
            priority: priority_value,
            completed: completed_opt,
          )

          case todo_actor.update_todo(ctx.todo_subject, id, patch) {
            Ok(updated_todo) ->
              todo_to_json(updated_todo)
              |> json.to_string
              |> wisp.json_response(200)
            Error(NotFound) ->
              json.object([#("error", json.string("not_found"))])
              |> json.to_string
              |> wisp.json_response(404)
            Error(_) ->
              json.object([#("error", json.string("internal_error"))])
              |> json.to_string
              |> wisp.json_response(500)
          }
        }
        Error(_) ->
          json.object([#("errors", json.array(["Invalid priority value"], json.string))])
          |> json.to_string
          |> wisp.json_response(400)
      }
    }
    Error(_) ->
      json.object([#("errors", json.array(["Invalid JSON in request body"], json.string))])
      |> json.to_string
      |> wisp.json_response(400)
  }
}

fn delete_todo_handler(req: wisp.Request, ctx: Context, id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  case is_valid_uuid(id) {
    False ->
      json.object([#("error", json.string("not_found"))])
      |> json.to_string
      |> wisp.json_response(404)
    True -> {
      case todo_actor.delete_todo(ctx.todo_subject, id) {
        Ok(True) -> wisp.response(204)
        Ok(False) | Error(NotFound) ->
          json.object([#("error", json.string("not_found"))])
          |> json.to_string
          |> wisp.json_response(404)
        Error(_) ->
          json.object([#("error", json.string("internal_error"))])
          |> json.to_string
          |> wisp.json_response(500)
      }
    }
  }
}

fn parse_priority_string(p: String) -> Result(Option(Priority), Nil) {
  case p {
    "low" -> Ok(Some(shared.Low))
    "medium" -> Ok(Some(shared.Medium))
    "high" -> Ok(Some(shared.High))
    _ -> Error(Nil)
  }
}

// UUID validation: 8-4-4-4-12 hex format (lowercase only)
fn is_valid_uuid(id: String) -> Bool {
  case string.is_empty(id) {
    True -> False
    False -> {
      let segments = string.split(id, "-")
      case segments {
        [s1, s2, s3, s4, s5] -> {
          case string.length(s1), string.length(s2), string.length(s3), string.length(s4), string.length(s5) {
            8, 4, 4, 4, 12 -> {
              let all_chars = s1 <> s2 <> s3 <> s4 <> s5
              is_valid_hex_string(all_chars)
            }
            _, _, _, _, _ -> False
          }
        }
        _ -> False
      }
    }
  }
}

fn is_valid_hex_string(s: String) -> Bool {
  let chars = string.to_graphemes(s)
  list.all(chars, is_valid_hex_char)
}

fn is_valid_hex_char(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "a" | "b" | "c" | "d" | "e" | "f" -> True
    _ -> False
  }
}
