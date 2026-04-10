import config.{type Config}
import gleam/erlang/process
import gleam/io
import services/store_service
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start store service actor
  let store_actor_result = store_service.start()

  case store_actor_result {
    Error(err) -> {
      io.println("Failed to start store service: " <> err)
      Error(err)
    }
    Ok(store_actor) -> {
      io.println("Store service started")

      // Create the HTTP handler with store actor
      let handler = router.make_handler(store_actor)

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
