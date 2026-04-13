import config.{type Config}
import gleam/erlang/process
import gleam/io
import todo_actor
import todo_store
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start the todo actor
  case todo_actor.start() {
    Ok(todo_actor_pid) -> {
      io.println("Todo actor started")

      // Create the store wrapper
      let store = todo_store.TodoStore(todo_actor_pid)

      // Create the HTTP handler with store
      let handler = router.make_handler(store)

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
