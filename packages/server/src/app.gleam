import app_supervisor
import config
import gleam/erlang/process
import gleam/io

pub fn main() {
  io.println("Starting boba-raider-8...")

  let cfg = config.load()
  io.println("Port: " <> config.port_to_string(cfg))

  case app_supervisor.start(cfg) {
    Ok(_) -> {
      io.println("Server started successfully!")
      process.sleep_forever()
    }
    Error(err) -> {
      io.println("Failed to start: " <> err)
    }
  }
}
