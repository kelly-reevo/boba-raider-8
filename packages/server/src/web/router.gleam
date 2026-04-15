import counter
import gleam/http
import gleam/json
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
      |> wisp.set_header("access-control-allow-methods", "GET, POST, OPTIONS")
      |> wisp.set_header("access-control-allow-headers", "Content-Type")
    _ ->
      next()
      |> wisp.set_header("access-control-allow-origin", "*")
      |> wisp.set_header("access-control-allow-methods", "GET, POST, OPTIONS")
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
