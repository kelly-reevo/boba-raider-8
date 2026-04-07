import auth/user_store
import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start user store actor
  case user_store.start() {
    Error(err) -> Error("Failed to start user store: " <> err)
    Ok(store) -> {
      io.println("User store started")

      // Create the HTTP handler with auth dependencies
      let handler = router.make_handler(store, cfg.jwt_secret)

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
