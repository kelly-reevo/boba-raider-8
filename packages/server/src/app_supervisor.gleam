import config.{type Config}
import gleam/erlang/process
import gleam/io
import todo_store
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start todo store actor first (dependency for HTTP handlers)
  case todo_store.start_and_register("todo_store") {
    Ok(todo_store_pid) -> {
      io.println("Todo store actor started")

      // Link to the todo store actor so we can restart it
      process.link(todo_store_pid)
      process.trap_exits(True)

      // Create the HTTP handler
      let handler = router.make_handler()

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(actor) -> {
          io.println("HTTP server actor started")

          // Link to the HTTP server actor
          let assert Ok(http_pid) = process.subject_owner(actor)
          process.link(http_pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
    Error(err) -> Error("Failed to start todo store: " <> err)
  }
}
