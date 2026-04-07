import envoy
import gleam/int
import gleam/result

pub type Config {
  Config(port: Int, jwt_secret: String)
}

pub fn load() -> Config {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(3000)

  let jwt_secret =
    envoy.get("JWT_SECRET")
    |> result.unwrap("dev-secret-change-in-production")

  Config(port: port, jwt_secret: jwt_secret)
}

pub fn port_to_string(cfg: Config) -> String {
  int.to_string(cfg.port)
}
