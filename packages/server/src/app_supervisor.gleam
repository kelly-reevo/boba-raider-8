import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router
import web/user_store

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start user store actor
  case user_store.start() {
    Ok(store) -> {
      io.println("User store started")

      // Create the HTTP handler with user store and JWT secret
      let handler = router.make_handler(store, cfg.jwt_secret)

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
    Error(err) -> Error("Failed to start user store: " <> err)
  }
}
