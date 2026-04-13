import boba_store
import config.{type Config}
import drink_store
import gleam/erlang/process
import gleam/io
import gleam/option.{None}
import rating_service
import store/store_service
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Start boba store (which starts drink_store and rating_service)
  case boba_store.start() {
    Error(err) -> {
      io.println("Failed to start boba store: " <> err)
      Error("Failed to start boba store: " <> err)
    }
    Ok(store) -> {
      // Initialize store service actor
      let store_srv = case store_service.start_with_publisher(None) {
        Error(err) -> {
          io.println("Failed to start store service: " <> err)
          panic as "Failed to start store service"
        }
        Ok(svc) -> svc
      }

      // Create the HTTP handler with store reference and services
      let handler = router.make_handler_with_store_and_services(store, store_srv)

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

/// Start for testing - starts services and makes them available globally for tests
pub fn start_link() -> Result(Nil, String) {
  io.println("Starting supervisor for test...")

  // Start boba store
  case boba_store.start() {
    Error(err) -> Error("Failed to start boba store: " <> err)
    Ok(_store) -> {
      // Start store service actor
      case store_service.start_with_publisher(None) {
        Error(err) -> Error("Failed to start store service: " <> err)
        Ok(_store_srv) -> {
          io.println("Store service started")
          // For tests, we rely on the router's test mode which creates fresh services
          Ok(Nil)
        }
      }
    }
  }
}
