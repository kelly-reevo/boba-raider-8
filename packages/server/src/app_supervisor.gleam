import config.{type Config}
import gleam/erlang/process
import gleam/io
import web/http_server_actor
import web/rating
import web/router
import web/store
import web/user

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start domain actors first (dependencies must be ready before HTTP)
  io.println("Starting store actor...")
  let assert Ok(store_actor) = store.start()

  io.println("Starting user actor...")
  let assert Ok(user_actor) = user.start()

  io.println("Starting rating actor...")
  let assert Ok(rating_actor) = rating.start()

  // Create the HTTP handler with actor references
  let handler = router.make_handler(store_actor, user_actor, rating_actor)

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
