import config.{type Config}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/otp/actor
import store/store_actor.{type StoreMessage}
import web/http_server_actor
import web/router
import web/user_store

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start the store actor for in-memory persistence
  let store_init = store_actor.new()
  let store_actor_result =
    actor.new(store_init)
    |> actor.on_message(fn(state, msg) { store_actor.handle_message(state, msg) })
    |> actor.start()

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
