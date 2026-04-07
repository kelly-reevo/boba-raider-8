import envoy
import gleam/int
import gleam/result

pub type Config {
  Config(port: Int, database_path: String)
}

pub fn load() -> Config {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(3000)

  let database_path =
    envoy.get("DATABASE_PATH")
    |> result.unwrap("boba_raider.db")

  Config(port: port, database_path: database_path)
}

pub fn port_to_string(cfg: Config) -> String {
  int.to_string(cfg.port)
}
