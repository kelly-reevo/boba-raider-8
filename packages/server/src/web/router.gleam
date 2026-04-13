import counter.{type CounterMsg}
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/string
import web/server.{type Request, type Response, Response}
import web/static

pub fn make_handler(
  counter: Subject(CounterMsg),
) -> fn(Request) -> Response {
  fn(request: Request) { route(request, counter) }
}

fn route(request: Request, counter: Subject(CounterMsg)) -> Response {
  case request.method, request.path {
    "GET", "/" -> static.serve_index()
    "GET", "/health" -> health_handler()
    "GET", "/api/health" -> health_handler()
    "GET", "/api/counter" -> get_counter(counter)
    "POST", "/api/counter/increment" -> increment_counter(counter)
    "POST", "/api/counter/decrement" -> decrement_counter(counter)
    "POST", "/api/counter/reset" -> reset_counter(counter)
    "OPTIONS", path -> route_options(path)
    "GET", path -> route_get(path)
    _, _ -> not_found()
  }
}

fn route_get(path: String) -> Response {
  case string.starts_with(path, "/static/") {
    True -> static.serve(path)
    False -> not_found()
  }
}

fn health_handler() -> Response {
  server.json_response(
    200,
    json.object([#("status", json.string("ok"))])
      |> json.to_string,
  )
}

fn not_found() -> Response {
  server.json_response(
    404,
    json.object([#("error", json.string("Not found"))])
      |> json.to_string,
  )
}

fn get_counter(counter: Subject(CounterMsg)) -> Response {
  counter.get_count(counter) |> counter_response
}

fn increment_counter(counter: Subject(CounterMsg)) -> Response {
  counter.increment(counter) |> counter_response
}

fn decrement_counter(counter: Subject(CounterMsg)) -> Response {
  counter.decrement(counter) |> counter_response
}

fn reset_counter(counter: Subject(CounterMsg)) -> Response {
  counter.reset(counter) |> counter_response
}

fn counter_response(count: Int) -> Response {
  let body =
    json.object([#("count", json.int(count))])
    |> json.to_string
  Response(
    status: 200,
    headers: cors_headers()
      |> dict.insert("Content-Type", "application/json"),
    body: body,
  )
}

fn route_options(path: String) -> Response {
  case string.starts_with(path, "/api/") {
    True -> Response(status: 204, headers: cors_headers(), body: "")
    False -> not_found()
  }
}

fn cors_headers() -> dict.Dict(String, String) {
  dict.from_list([
    #("Access-Control-Allow-Origin", "*"),
    #("Access-Control-Allow-Methods", "GET, POST, OPTIONS"),
    #("Access-Control-Allow-Headers", "Content-Type"),
  ])
}
