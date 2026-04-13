// Integration test for PATCH /api/todos/:id - empty body handling

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/option.{None}
import shared.{Low}
import todo_store
import web/router
import web/server.{Request}

fn create_test_todo() {
  let attrs = shared.new_todo_attrs(title: "Test Todo", description: None, priority: Low)
  let assert Ok(todo_item) = todo_store.create(attrs)
  todo_item
}

fn build_patch_request(id: String, body: String) {
  Request(
    method: "PATCH",
    path: "/api/todos/" <> id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
}

fn decode_todo_response(json_string: String) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.optional(decode.string))
    use priority_str <- decode.field("priority", decode.string)
    use completed <- decode.field("completed", decode.bool)
    use created_at <- decode.field("created_at", decode.string)
    use updated_at <- decode.field("updated_at", decode.string)
    decode.success(#(id, title, description, priority_str, completed, created_at, updated_at))
  }
  case json.parse(from: json_string, using: decoder) {
    Ok(#(id, title, description, priority_str, completed, created_at, updated_at)) -> {
      case priority_str {
        "low" -> Ok(shared.Todo(id, title, description, Low, completed, created_at, updated_at))
        "medium" -> Ok(shared.Todo(id, title, description, shared.Medium, completed, created_at, updated_at))
        "high" -> Ok(shared.Todo(id, title, description, shared.High, completed, created_at, updated_at))
        _ -> Error("Invalid priority")
      }
    }
    Error(_) -> Error("Failed to decode")
  }
}

pub fn patch_todo_empty_body_returns_unchanged_test() {
  let _ = todo_store.stop()
  let assert Ok(_) = todo_store.start()
  let existing = create_test_todo()
  let id = existing.id
  let handler = router.make_handler()

  let original_title = existing.title
  let original_description = existing.description
  let original_priority = existing.priority
  let original_completed = existing.completed

  let patch_body = "{}"
  let req = build_patch_request(id, patch_body)
  let res = handler(req)

  res.status |> should.equal(200)

  let assert Ok(updated) = decode_todo_response(res.body)
  updated.id |> should.equal(id)
  updated.title |> should.equal(original_title)
  updated.description |> should.equal(original_description)
  updated.priority |> should.equal(original_priority)
  updated.completed |> should.equal(original_completed)
}
