import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import web/server.{type Request, type Response}

pub type HttpServerMsg {
  Shutdown
}

pub type HttpServer =
  Subject(HttpServerMsg)

@external(erlang, "server_ffi", "start")
fn start_http_server(
  port: Int,
  handler: fn(Request) -> Response,
) -> Result(ServerHandle, String)

@external(erlang, "server_ffi", "stop")
fn stop_http_server(handle: ServerHandle) -> Nil

pub type ServerHandle

pub fn start(
  port: Int,
  handler: fn(Request) -> Response,
) -> Result(HttpServer, String) {
  case start_http_server(port, handler) {
    Ok(handle) -> {
      let assert Ok(started) =
        actor.new(handle)
        |> actor.on_message(fn(state, msg) {
          case msg {
            Shutdown -> {
              stop_http_server(state)
              actor.stop()
            }
          }
        })
        |> actor.start()
      Ok(started.data)
    }
    Error(err) -> Error(err)
  }
}

pub fn stop(server: HttpServer) -> Nil {
  actor.send(server, Shutdown)
}
