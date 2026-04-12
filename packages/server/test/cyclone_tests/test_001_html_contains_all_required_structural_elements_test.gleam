import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import web/router
import web/server.{Request}

pub fn main() {
  gleeunit.main()
}

// Comprehensive test validating all acceptance criteria at once
pub fn get_root_returns_complete_html_structure_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  // Status 200
  res.status |> should.equal(200)

  // Content type text/html
  let content_type = get_header(res.headers, "content-type")
  content_type |> should.equal(Some("text/html"))

  let body = res.body

  // Contains #todo-list container
  body |> string.contains("<div id=\"todo-list\"") |> should.be_true()

  // Contains #add-todo-form
  body |> string.contains("<form id=\"add-todo-form\"") |> should.be_true()

  // Contains title input
  body |> string.contains("name=\"title\"") |> should.be_true()

  // Contains description input
  body |> string.contains("name=\"description\"") |> should.be_true()

  // Contains filter buttons with data-filter attributes
  body |> string.contains("data-filter=\"all\"") |> should.be_true()
  body |> string.contains("data-filter=\"active\"") |> should.be_true()
  body |> string.contains("data-filter=\"completed\"") |> should.be_true()

  // Contains script reference
  body |> string.contains("<script") |> should.be_true()
  body |> string.contains("client") |> should.be_true()
}

// Edge case: Verify form has submit button
pub fn add_todo_form_has_submit_button_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  // Form should have a submit button
  body |> string.contains("type=\"submit\"") |> should.be_true()
}

// Edge case: Verify title input is required
pub fn title_input_is_required_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  // Title input should have required attribute
  body |> string.contains("name=\"title\"") |> should.be_true()
  body |> string.contains("required") |> should.be_true()
}

fn get_header(headers, name: String) {
  case dict.get(headers, name) {
    Ok(value) -> Some(value)
    Error(_) -> {
      // Try case-insensitive lookup
      let lower_name = string.lowercase(name)
      let found =
        dict.fold(headers, option.None, fn(acc, key, value) {
          case acc {
            Some(_) -> acc
            None ->
              case string.lowercase(key) == lower_name {
                True -> Some(value)
                False -> None
              }
          }
        })
      found
    }
  }
}
