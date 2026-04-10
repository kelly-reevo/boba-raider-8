import envoy
import gleam/int
import gleam/result
import infrastructure/storage_config

pub type Config {
  Config(port: Int, storage: storage_config.StorageConfig)
}

pub fn load() -> Config {
  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(3000)

  let storage = storage_config.load()

  Config(port: port, storage: storage)
}

pub fn port_to_string(cfg: Config) -> String {
  int.to_string(cfg.port)
}
