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

// Edge case: GET /nonexistent should return 404
pub fn get_nonexistent_route_returns_404_test() {
  let req = Request(method: "GET", path: "/nonexistent", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  res.status |> should.equal(404)
}

// Edge case: GET /api/todos should not return HTML (different content type)
pub fn get_api_endpoint_returns_json_not_html_test() {
  let req = Request(method: "GET", path: "/api/todos", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  // Should not be HTML content type
  let content_type = get_header(res.headers, "content-type")
  case content_type {
    Some(ct) -> ct |> should.not_equal("text/html")
    None -> True |> should.be_true()
  }
}

// Edge case: POST / should return 405 method not allowed
pub fn post_to_root_returns_405_test() {
  let req = Request(method: "POST", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  res.status |> should.equal(405)
}

// Edge case: HTML page is not empty
pub fn html_page_is_not_empty_test() {
  let req = Request(method: "GET", path: "/", headers: dict.new(), body: "")

  let res = router.handle_request(req)

  res.status |> should.equal(200)

  let body_length = res.body |> string.length()

  should.be_true(body_length > 100)
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
