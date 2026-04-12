import gleeunit
import gleeunit/should
import shared
import gleam/string
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Test: Empty string description is valid (0 chars)
pub fn description_empty_string_is_valid_test() {
  let result = shared.new_todo(
    title: "Task with empty desc",
    description: Some(""),
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> item.description |> should.equal(Some(""))
    Error(_) -> should.fail()
  }
}

// Test: None description is valid (null/optional)
pub fn description_none_is_valid_test() {
  let result = shared.new_todo(
    title: "Task with no desc",
    description: None,
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> item.description |> should.equal(None)
    Error(_) -> should.fail()
  }
}

// Test: Description with exactly 1000 characters is valid
pub fn description_exactly_1000_chars_is_valid_test() {
  let long_desc = string.repeat("b", 1000)
  let result = shared.new_todo(
    title: "Task with long desc",
    description: Some(long_desc),
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> item.description |> should.equal(Some(long_desc))
    Error(_) -> should.fail()
  }
}
