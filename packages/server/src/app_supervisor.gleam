import config.{type Config}
import data/drink_store
import gleam/erlang/process
import gleam/io
import store
import web/http_server_actor
import web/rating
import web/router
import web/store
import web/user

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting Supervisor...")

  // Start storage actor first
  case store.start() {
    Error(err) -> Error("Failed to start store: " <> err)
    Ok(store) -> {
      io.println("Store actor started")

      // Create the HTTP handler with store access
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

import gleam/int
