import envoy
import gleam/result
import gleam/string

pub type StorageType {
  S3
  Local
}

pub type S3Config {
  S3Config(
    bucket: String,
    region: String,
    access_key: String,
    secret_key: String,
  )
}

pub type StorageConfig {
  S3Storage(S3Config)
  LocalStorage(uploads_path: String, serve_path: String)
}

pub fn load() -> StorageConfig {
  let storage_type =
    envoy.get("STORAGE_TYPE")
    |> result.unwrap("local")
    |> string.lowercase

  case storage_type {
    "s3" -> load_s3_config()
    _ -> load_local_config()
  }
}

fn load_s3_config() -> StorageConfig {
  let bucket = envoy.get("S3_BUCKET") |> result.unwrap("")
  let region = envoy.get("S3_REGION") |> result.unwrap("")
  let access_key = envoy.get("S3_ACCESS_KEY") |> result.unwrap("")
  let secret_key = envoy.get("S3_SECRET_KEY") |> result.unwrap("")

  S3Storage(S3Config(
    bucket: bucket,
    region: region,
    access_key: access_key,
    secret_key: secret_key,
  ))
}

fn load_local_config() -> StorageConfig {
  LocalStorage(uploads_path: "/uploads", serve_path: "/uploads/:filename")
}

pub fn get_uploads_path(config: StorageConfig) -> String {
  case config {
    LocalStorage(uploads_path, _) -> uploads_path
    S3Storage(_) -> ""
  }
}

pub fn get_serve_path(config: StorageConfig) -> String {
  case config {
    LocalStorage(_, serve_path) -> serve_path
    S3Storage(_) -> ""
  }
}

pub fn is_s3(config: StorageConfig) -> Bool {
  case config {
    S3Storage(_) -> True
    LocalStorage(_, _) -> False
  }
}
