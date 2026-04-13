import config.{type Config}
import gleam/erlang/process
import gleam/io
import todo_actor
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

<<<<<<< HEAD
  // Start the todo actor first
=======
  // Start the todo actor
>>>>>>> cyclone/feat-361714986/api-list-todos/api-list-todos-simplicity
  case todo_actor.start() {
    Ok(todo_actor_pid) -> {
      io.println("Todo actor started")

<<<<<<< HEAD
      // Create the HTTP handler with todo_actor reference
=======
      // Create the HTTP handler with todo actor
>>>>>>> cyclone/feat-361714986/api-list-todos/api-list-todos-simplicity
      let handler = router.make_handler(todo_actor_pid)

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
    Error(err) -> Error("Failed to start todo actor: " <> err)
  }
}
