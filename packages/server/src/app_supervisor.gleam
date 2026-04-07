import config.{type Config}
import drink_store
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start drink store actor
  let store = case drink_store.start() {
    Ok(s) -> s
    Error(_) -> {
      io.println("Failed to start drink store")
      panic as "Failed to start drink store"
    }
  }
  io.println("Drink store started")

  // Create the HTTP handler with drink store
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
