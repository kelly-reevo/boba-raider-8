import data.{type Store, new_store}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import web/server.{type Request, type Response}

pub type HttpServerMsg {
  Shutdown
}

pub type HttpServer =
  Subject(HttpServerMsg)

@external(erlang, "server_ffi", "start_stateful")
fn start_http_server(
  port: Int,
  handler: fn(Request) -> Response,
) -> Result(ServerHandle, String)

@external(erlang, "server_ffi", "stop")
fn stop_http_server(handle: ServerHandle) -> Nil

pub type ServerHandle

pub fn start(
  port: Int,
  handler: fn(Request, Store) -> Response,
) -> Result(HttpServer, String) {
  // Create a fresh store for this server instance
  let store = new_store()

  // Create handler that closes over the store
  let http_handler = fn(req: Request) { handler(req, store) }

  case start_http_server(port, http_handler) {
    Ok(handle) -> {
      // Create actor to manage the server lifecycle
      case
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
      {
        Ok(started) -> Ok(started.data)
        Error(_) -> {
          stop_http_server(handle)
          Error("Failed to start actor")
        }
      }
    }
    Error(err) -> Error(err)
  }
}

pub fn stop(server: HttpServer) -> Nil {
  actor.send(server, Shutdown)
}
