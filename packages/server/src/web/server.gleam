import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type Request {
  Request(
    method: String,
    path: String,
    query: Option(String),
    headers: Dict(String, String),
    body: String,
  )
}

pub type Response {
  Response(status: Int, headers: Dict(String, String), body: String)
}

pub fn json_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "application/json")]),
    body: body,
  )
}

pub fn html_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/html; charset=utf-8")]),
    body: body,
  )
}

pub fn text_response(status: Int, body: String) -> Response {
  Response(
    status: status,
    headers: dict.from_list([#("Content-Type", "text/plain")]),
    body: body,
  )
}
