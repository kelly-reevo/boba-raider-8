import actors/todo_actor
import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start the todo actor first
  case todo_actor.start() {
    Ok(actor) -> {
      io.println("Todo actor started")

      // Create the HTTP handler with the actor reference
      let handler = router.make_handler(actor)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(http_actor) -> {
          // Set up trap for clean shutdown
          process.trap_exits(True)
          io.println("HTTP server actor started")

          // Link to the actor so we crash if it crashes
          let assert Ok(pid) = process.subject_owner(http_actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
    Error(err) -> Error("Failed to start todo actor: " <> err)
  }
}
