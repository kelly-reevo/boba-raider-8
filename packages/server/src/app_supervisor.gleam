import auth/user_store
import config.{type Config}
import db/database
import drink_store
import gleam/erlang/process
import gleam/io
import store_repo
import web/http_server_actor
import web/rating_store
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Initialize database
  case database.init(cfg.database_path) {
    Ok(_conn) -> {
      io.println("Database ready")

      // Start drink store actor
      let drinks = case drink_store.start() {
        Ok(s) -> s
        Error(_) -> {
          io.println("Failed to start drink store")
          panic as "Failed to start drink store"
        }
      }
      io.println("Drink store started")

      // Start store repository actor
      case store_repo.start() {
        Error(err) -> Error("Failed to start store repo: " <> err)
        Ok(stores) -> {
          io.println("Store repository started")

          // Start rating store actor
          case rating_store.start() {
            Error(err) -> Error("Failed to start rating store: " <> err)
            Ok(ratings) -> {
              io.println("Rating store started")

              // Start user store actor
              case user_store.start() {
                Error(err) -> Error("Failed to start user store: " <> err)
                Ok(users) -> {
                  io.println("User store started")

                  // Create the HTTP handler with all dependencies
                  let handler =
                    router.make_handler(
                      users,
                      drinks,
                      stores,
                      ratings,
                      cfg.jwt_secret,
                    )

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
                    Error(err) ->
                      Error("Failed to start HTTP server: " <> err)
                  }
                }
              }
            }
          }
        }
      }
    }
    Error(err) -> Error("Failed to initialize database: " <> err)
  }
}
