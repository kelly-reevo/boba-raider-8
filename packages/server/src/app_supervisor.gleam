import config.{type Config}
import gleam/erlang/process
import gleam/io
import services/store_service
import web/http_server_actor
import web/router
import web/user_store

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start user store actor for authentication
  case user_store.start() {
    Error(err) -> {
      io.println("Failed to start user store: " <> err)
      Error(err)
    }
    Ok(user_store_ref) -> {
      io.println("User store started")

      // Start store service actor for store management
      case store_service.start() {
        Error(err) -> {
          io.println("Failed to start store service: " <> err)
          Error(err)
        }
        Ok(store_actor) -> {
          io.println("Store service started")

          // Create the HTTP handler with both stores and JWT secret
          let handler = router.make_handler(user_store_ref, store_actor, cfg.jwt_secret)

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
            Error(err) -> {
              io.println("Failed to start HTTP server: " <> err)
              Error(err)
            }
          }
        }
      }
    }
  }
}
