import config.{type Config}
import drink_store
import gleam/erlang/process
import gleam/io
import rating_service
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start drink store
  let drink_store_result = drink_store.start()

  case drink_store_result {
    Error(err) -> {
      io.println("Failed to start drink store: " <> err)
      Error("Failed to start drink store")
    }
    Ok(store) -> {
      io.println("Drink store started")

      // Start rating service with drink store dependency
      case rating_service.start(store) {
        Error(err) -> {
          io.println("Failed to start rating service: " <> err)
          Error("Failed to start rating service")
        }
        Ok(rating_svc) -> {
          io.println("Rating service started")

          // Create the HTTP handler with service dependencies
          let handler = router.make_handler(store, rating_svc)

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
  }
}
