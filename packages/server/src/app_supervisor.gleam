import config.{type Config}
import gleam/erlang/process
import gleam/io
import store/ratings_store
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Initialize ratings store
  let ratings_table = ratings_store.init()
  io.println("Ratings store initialized")

  // Create the HTTP handler with ratings table
  let handler = router.make_handler(ratings_table)

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
