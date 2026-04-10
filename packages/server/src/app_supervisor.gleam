import config.{type Config}
import data/drink_store
import gleam/erlang/process
import gleam/io
import storage/store
import web/http_server_actor
import web/rating
import web/router
import web/store
import web/user

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Create the HTTP handler with store access
  let handler = router.make_handler()

  io.println("Starting user actor...")
  let assert Ok(user_actor) = user.start()

  io.println("Starting rating actor...")
  let assert Ok(rating_actor) = rating.start()

  // Create the HTTP handler with actor references
  let handler = router.make_handler(store_actor, user_actor, rating_actor)

  // Create the HTTP handler with store access
  let handler = router.make_handler(app_store)

      // Create the HTTP handler with store access
      let handler = router.make_handler_with_store(store)

      // Start HTTP server actor
      case http_server_actor.start(cfg.port, handler) {
        Ok(actor) -> {
          process.trap_exits(True)
          io.println("HTTP server actor started")

          let assert Ok(pid) = process.subject_owner(actor)
          process.link(pid)

          Ok(Nil)
        }
        Error(err) -> Error("Failed to start HTTP server: " <> err)
      }
    }
    Error(err) -> Error("Failed to start store actor: " <> err)
  }
}
