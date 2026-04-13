import config.{type Config}
import drink_store
import gleam/erlang/process
import gleam/io
import rating_service
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start drink store actor
  let drink_store_result = drink_store.start()

  // Start rating service actor (depends on drink store)
  let rating_service_result = case drink_store_result {
    Ok(ds) -> rating_service.start(ds)
    Error(err) -> Error("Failed to start drink store: " <> err)
  }

  case drink_store_result, rating_service_result {
    Ok(drink_store_ref), Ok(rating_service_ref) -> {
      // Create the HTTP handler with store references
      let handler = router.make_handler(drink_store_ref, rating_service_ref)

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
    Error(err), _ -> Error("Failed to start drink store: " <> err)
    _, Error(err) -> Error("Failed to start rating service: " <> err)
  }
}
