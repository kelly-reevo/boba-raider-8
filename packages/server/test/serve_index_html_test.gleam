// Integration test: GET / serves HTML page with correct content type
import gleeunit
import gleeunit/should
import gleam/string
import gleam/dict
import todo_store
import web/router
import web/server.{Request, type Response}

pub fn main() {
  gleeunit.main()
}

fn build_get_request(path: String) {
  Request(
    method: "GET",
    path: path,
    headers: dict.from_list([]),
    body: "",
  )
}

fn get_header(response: Response, name: String) {
  let headers = response.headers
  case dict.get(headers, name) {
    Ok(value) -> Ok(value)
    Error(_) -> Error("Header not found")
  }
}

pub fn get_root_returns_200_with_html_content_type_test() {
  // Given: Server is running
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // When: GET / request is made
  let request = build_get_request("/")
  let response = handler(request)

  // Then: Returns 200 with text/html content type
  response.status
  |> should.equal(200)

  get_header(response, "Content-Type")
  |> should.equal(Ok("text/html"))
}

pub fn html_contains_todo_list_element_test() {
  // Given: Server is running
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // When: GET / request is made
  let request = build_get_request("/")
  let response = handler(request)
  let body = response.body

  // Then: HTML contains element with id 'todo-list'
  body
  |> string.contains("<div id=\"todo-list\"")
  |> should.be_true()
}

pub fn html_contains_add_todo_form_test() {
  // Given: Server is running
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // When: GET / request is made
  let request = build_get_request("/")
  let response = handler(request)
  let body = response.body

  // Then: HTML contains form with id 'add-todo-form'
  body
  |> string.contains("<form id=\"add-todo-form\"")
  |> should.be_true()

  // And: Form has input[name='title']
  body
  |> string.contains("<input")
  |> should.be_true()

  body
  |> string.contains("name=\"title\"")
  |> should.be_true()

  // And: Form has textarea[name='description']
  body
  |> string.contains("<textarea")
  |> should.be_true()

  body
  |> string.contains("name=\"description\"")
  |> should.be_true()
}

pub fn html_contains_filter_controls_test() {
  // Given: Server is running
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // When: GET / request is made
  let request = build_get_request("/")
  let response = handler(request)
  let body = response.body

  // Then: HTML contains filter controls with id 'filter-controls'
  body
  |> string.contains("<div id=\"filter-controls\"")
  |> should.be_true()

  // And: Contains controls for 'all', 'active', 'completed'
  body
  |> string.contains("all")
  |> should.be_true()

  body
  |> string.contains("active")
  |> should.be_true()

  body
  |> string.contains("completed")
  |> should.be_true()
}

pub fn html_contains_client_script_reference_test() {
  // Given: Server is running
  let _ = todo_store.stop()
  let assert Ok(store) = todo_store.start()
  let handler = router.make_handler(store)

  // When: GET / request is made
  let request = build_get_request("/")
  let response = handler(request)
  let body = response.body

  // Then: HTML contains script reference to client.js
  body
  |> string.contains("<script")
  |> should.be_true()

  body
  |> string.contains("client.js")
  |> should.be_true()
}
