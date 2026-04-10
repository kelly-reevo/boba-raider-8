import envoy
import gleam/int
import gleam/result

pub type Config {
  Config(
    port: Int,
    database_url: String,
  )
}

pub fn load() -> Config {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(3000)

  let database_url =
    envoy.get("DATABASE_URL")
    |> result.unwrap("postgres://localhost:5432/boba_raider_8_dev")

  Config(
    port: port,
    database_url: database_url,
  )
}

pub fn port_to_string(cfg: Config) -> String {
  int.to_string(cfg.port)
}
