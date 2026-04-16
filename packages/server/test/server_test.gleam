import gleeunit
import gleeunit/should
import config

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  // The default port is 3777 per config.gleam
  cfg.port
  |> should.equal(3777)
}
