import envoy
import gleam/int
import gleam/result

pub type Config {
  Config(port: Int)
}

pub fn load() -> Config {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(3777)

  Config(port: port)
}

pub fn port_to_string(cfg: Config) -> String {
  int.to_string(cfg.port)
}
