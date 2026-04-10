import config.{type Config}
import db/database
import db/migrations
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/int
import gleam/string
import web/http_server_actor
import web/router

pub fn start(cfg: Config) -> Result(Nil, String) {
  io.println("Starting supervisor...")

  // Connect to database
  io.println("Connecting to database...")
  let db_result = database.connect(cfg.database_url)

  case db_result {
    Ok(conn) -> {
      io.println("Database connected")

      // Run migrations
      case migrations.run_migrations(conn, "priv/migrations") {
        Ok(versions) -> {
          case versions {
            [] -> io.println("No pending migrations")
            _ -> {
              let applied = versions |> list.map(int.to_string) |> string.join(", ")
              io.println("Applied migrations: " <> applied)
            }
          }
        }
        Error(e) -> {
          io.println("Migration error: " <> migrations.error_to_string(e))
        }
      }

      // Create the HTTP handler
      let handler = router.make_handler()

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
    Error(err) -> {
      io.println("Failed to connect to database: " <> err)
      Error("Database connection failed")
    }
  }
}
