import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/rating_store
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start the rating store actor
  case rating_store.start() {
    Error(err) -> Error("Failed to start rating store: " <> err)
    Ok(store) -> {
      io.println("Rating store started")

      // Create the HTTP handler with the store
      let handler = router.make_handler(store)

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
  }
}
