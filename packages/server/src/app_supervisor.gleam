import config.{type Config}
import drink_store
import gleam/erlang/process
import gleam/io
import rating_service
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Initialize stores
  let assert Ok(drink_store) = drink_store.start()

  // Initialize services with dependencies
  let assert Ok(rating_service) = rating_service.start(drink_store)

  // Create the router context with services
  let ctx = router.Context(rating_service: rating_service)
  let handler = router.make_handler_with_context(ctx)

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
