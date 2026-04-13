import boba_store
import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start boba store (which starts drink_store and rating_service)
  case boba_store.start() {
    Error(err) -> {
      io.println("Failed to start boba store: " <> err)
      Error("Failed to start boba store: " <> err)
    }
    Ok(store) -> {
      // Create the HTTP handler with store reference
      let handler = router.make_handler(store)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(actor) -> {
          // Set up trap for clean shutdown
          process.trap_exits(True)
          io.println("HTTP server actor started")

          // Link to the actor so we crash if it crashes
          let assert Ok(pid) = process.subject_owner(actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
  }
}
