// Integration test for PATCH /api/todos/:id - 404 handling

import gleeunit/should
import gleam/json
import gleam/dict
import gleam/dynamic/decode
import todo_store
import web/router
import web/server.{Request}

fn build_patch_request(id: String, body: String) {
  Request(
    method: "PATCH",
    path: "/api/todos/" <> id,
    headers: dict.from_list([#("content-type", "application/json")]),
    body: body,
  )
}

fn decode_404_error_response(json_string: String) -> String {
  let decoder = {
    use error <- decode.field("error", decode.string)
    decode.success(error)
  }
  case json.parse(from: json_string, using: decoder) {
    Ok(msg) -> msg
    Error(_) -> "Unknown error"
  }
}

pub fn patch_nonexistent_todo_returns_404_test() {
  let _ = todo_store.stop()
  let assert Ok(_) = todo_store.start()
  let fake_id = "00000000-0000-0000-0000-000000000000"
  let handler = router.make_handler()

  let patch_body = json.object([#("title", json.string("Updated Title"))]) |> json.to_string()
  let req = build_patch_request(fake_id, patch_body)
  let res = handler(req)

  res.status |> should.equal(404)

  let error_msg = decode_404_error_response(res.body)
  error_msg |> should.equal("Todo not found")
}
