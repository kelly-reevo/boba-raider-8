import config.{type Config}
import gleam/erlang/process
import gleam/io
import storage/store
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Create the in-memory store
  let app_store = store.new()
  io.println("Store initialized")

  // Create the HTTP handler with store access
  let handler = router.make_handler(app_store)

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
