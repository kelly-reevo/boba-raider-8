import config.{type Config}
import counter
import gleam/erlang/process
import gleam/io
import todo_actor
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start counter actor
  let assert Ok(counter_subject) = counter.start()
  io.println("Counter actor started")

  // Start todo actor
  let assert Ok(todo_subject) = todo_actor.start()
  io.println("Todo actor started")

  // Create the HTTP handler with counter and todo actor access
  let handler = router.make_handler(counter_subject, todo_subject)

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
