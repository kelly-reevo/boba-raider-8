import config.{type Config}
import gleam/erlang/process
import gleam/io
import store_repo
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start store repository actor
  case store_repo.start() {
    Error(err) -> Error("Failed to start store repo: " <> err)
    Ok(repo) -> {
      io.println("Store repository started")

      // Create the HTTP handler with store repo
      let handler = router.make_handler(repo)

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
  }
}
