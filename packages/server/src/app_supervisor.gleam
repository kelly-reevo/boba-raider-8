import config.{type Config}
import data/drink_store
import gleam/erlang/process
import gleam/io
import store/rating_store
import web/http_server_actor
import web/rating
import web/router
import web/store
import web/user

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start rating store actor
  case rating_store.start() {
    Error(err) -> {
      io.println("Failed to start rating store: " <> err)
      Error(err)
    }

    Ok(store) -> {
      io.println("Rating store started")

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
