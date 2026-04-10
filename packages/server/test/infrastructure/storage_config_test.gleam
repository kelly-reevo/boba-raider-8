import gleeunit/should
import infrastructure/storage_config

pub fn local_storage_by_default_test() {
  let config = storage_config.load()

  config
  |> storage_config.is_s3()
  |> should.be_false()
}

pub fn local_storage_paths_test() {
  let config = storage_config.LocalStorage("/uploads", "/uploads/:filename")

  storage_config.get_uploads_path(config)
  |> should.equal("/uploads")

  storage_config.get_serve_path(config)
  |> should.equal("/uploads/:filename")
}

pub fn s3_storage_config_test() {
  let s3_cfg = storage_config.S3Config(
    bucket: "my-bucket",
    region: "us-east-1",
    access_key: "AKIAIOSFODNN7EXAMPLE",
    secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  )
  let config = storage_config.S3Storage(s3_cfg)

  storage_config.is_s3(config)
  |> should.be_true()
}
