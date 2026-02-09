import gleeunit
import gleeunit/should
import shared

pub fn main() {
  gleeunit.main()
}

pub fn error_message_test() {
  shared.NotFound("item")
  |> shared.error_message
  |> should.equal("Not found: item")
}
