import config.{type Config}
import gleam/erlang/process
import gleam/io
import rating_store
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting Supervisor...")

  // Start rating store actor first
  io.println("Starting rating store...")
  case rating_store.start() {
    Error(err) -> Error("Failed to start rating store: " <> err)
    Ok(rating_store) -> {
      io.println("Rating store started")

      // Create router state with stores
      let router_state = router.RouterState(rating_store:)

      // Create the HTTP handler with state
      let handler = router.make_handler(router_state)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(actor) -> {
          // Set up trap for clean shutdown
          process.trap_exits(True)
          io.println("HTTP server actor started on port " <> int.to_string(cfg.port))

          // Link to the actor so we crash if it crashes
          let assert Ok(pid) = process.subject_owner(actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> {
          // Clean up rating store on HTTP server failure
          rating_store.stop(rating_store)
          Error("Failed to start HTTP server: " <> err)
        }
      }
    }
  }
}

import gleam/int
