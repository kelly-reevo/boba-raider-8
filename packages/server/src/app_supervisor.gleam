import config.{type Config}
import gleam/erlang/process
import gleam/io
import gleam/result
import store/store_data
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start store data actor
  use store_actor <- result.try(
    store_data.start()
    |> result.map_error(fn(_) { "Failed to start store data actor" })
  )
  io.println("Store data actor started")

  // Create the HTTP handler with store actor
  let handler = router.make_handler(store_actor)

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
