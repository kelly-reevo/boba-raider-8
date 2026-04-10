import config.{type Config}
import data/drink_store
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import store/store_actor.{type StoreMessage}
import web/http_server_actor
import web/router
import web/user_store

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start the drink store actor
  let drink_store = drink_store.start()
  io.println("Drink store started")

  // Create the HTTP handler with drink store
  let handler = router.make_handler(drink_store)

  case store_actor_result {
    Error(_) -> Error("Failed to start store actor")
    Ok(started) -> {
      let store_actor_ref: Subject(StoreMessage) = started.data
      io.println("Store actor started")

      // Create the HTTP handler with store actor
      let handler = router.make_handler(store_actor_ref)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(http_actor) -> {
          // Set up trap for clean shutdown
          process.trap_exits(True)
          io.println("HTTP server actor started on port " <> int.to_string(cfg.port))

          // Link to the actor so we crash if it crashes
          let assert Ok(pid) = process.subject_owner(http_actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
  }
}
