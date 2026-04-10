import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router
import db/store_actor

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start store actor first
  case store_actor.start() {
    Ok(store) -> {
      io.println("Store actor started")

      // Create the HTTP handler with store access
      let handler = router.make_handler_with_store(store)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(actor) -> {
          process.trap_exits(True)
          io.println("HTTP server actor started")

          let assert Ok(pid) = process.subject_owner(actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
    Error(err) -> Error("Failed to start store actor: " <> err)
  }
}
