// Integration test for PATCH /api/todos/:id - priority enum validation

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/list
import gleam/option.{None}
import gleam/dynamic/decode
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

fn decode_422_errors_response(json_string: String) -> List(#(String, String)) {
  let error_decoder = {
    use field <- decode.field("field", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(#(field, message))
  }
  let decoder = {
    use errors <- decode.field("errors", decode.list(error_decoder))
    decode.success(errors)
  }
  case json.parse(from: json_string, using: decoder) {
    Ok(errors) -> errors
    Error(_) -> []
  }
}

pub fn patch_todo_invalid_priority_returns_422_test() {
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let existing = create_test_todo()
  let id = existing.id
  let handler = router.make_handler(store)

  let patch_body = json.object([#("priority", json.string("urgent"))]) |> json.to_string()
  let req = build_patch_request(id, patch_body)
  let res = handler(req)

  res.status |> should.equal(422)

  let errors = decode_422_errors_response(res.body)
  should.be_true(!list.is_empty(errors))
}
