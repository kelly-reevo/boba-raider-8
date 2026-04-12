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

// Test: GET / returns 200 OK with text/html content type
pub fn get_root_returns_200_with_html_content_type_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  res.status |> should.equal(200)
  get_header(res.headers, "content-type") |> should.equal(Some("text/html"))
}

// Test: HTML contains #todo-list container div
pub fn html_contains_todo_list_container_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  body |> string.contains("<div id=\"todo-list\"") |> should.be_true()
  body |> string.contains("</div>") |> should.be_true()
}

// Test: HTML contains add todo form with title and description inputs
pub fn html_contains_add_todo_form_with_inputs_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  body |> string.contains("<form id=\"add-todo-form\"") |> should.be_true()
  body |> string.contains("name=\"title\"") |> should.be_true()
  body |> string.contains("name=\"description\"") |> should.be_true()
}

// Test: HTML contains filter buttons with data-filter attributes
pub fn html_contains_filter_buttons_with_data_filter_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  body |> string.contains("data-filter=\"all\"") |> should.be_true()
  body |> string.contains("data-filter=\"active\"") |> should.be_true()
  body |> string.contains("data-filter=\"completed\"") |> should.be_true()
}

// Test: HTML contains script tag loading client.js
pub fn html_contains_client_script_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  body |> string.contains("<script") |> should.be_true()
  body |> string.contains("client") |> should.be_true()
  body |> string.contains("</script>") |> should.be_true()
}

// Test: HTML is complete valid HTML document structure
pub fn html_is_complete_document_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)
  let body = res.body

  body |> string.contains("<html>") |> should.be_true()
  body |> string.contains("</html>") |> should.be_true()
  body |> string.contains("<head>") |> should.be_true()
  body |> string.contains("</head>") |> should.be_true()
  body |> string.contains("<body>") |> should.be_true()
  body |> string.contains("</body>") |> should.be_true()
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
