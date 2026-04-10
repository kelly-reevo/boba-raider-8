import config.{type Config}
import gleam/erlang/process
import gleam/io
import users
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Initialize user store
  case users.init_store() {
    Ok(store) -> {
      io.println("User store initialized")

      // Create the HTTP handler with store
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
    Error(err) -> {
      io.println("Failed to initialize user store: " <> err)
      Error(err)
    }
  }
}
