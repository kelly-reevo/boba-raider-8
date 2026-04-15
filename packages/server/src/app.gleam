import config
import counter
import gleam/erlang/process
import gleam/io
import mist
import web/context.{Context}
import web/router
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  io.println("Starting boba-raider-8...")

  let cfg = config.load()
  io.println("Port: " <> config.port_to_string(cfg))

  let assert Ok(counter_subject) = counter.start()

  let assert Ok(priv) = wisp.priv_directory("server")
  let ctx = Context(counter: counter_subject, static_directory: priv <> "/static")

  let handler = fn(req) { router.handle_request(req, ctx) }
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(cfg.port)
    |> mist.start

  io.println("Server started successfully!")
  process.sleep_forever()
}
