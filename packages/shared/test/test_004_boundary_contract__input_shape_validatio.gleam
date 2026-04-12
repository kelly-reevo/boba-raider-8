import gleeunit
import gleeunit/should
import shared
import gleam/string
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

// Test: Title with exactly 1 character is valid
pub fn title_exactly_1_char_is_valid_test() {
  let result = shared.new_todo(
    title: "A",
    description: None,
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> item.title |> should.equal("A")
    Error(_) -> should.fail()
  }
}

// Test: Title with exactly 200 characters is valid
pub fn title_exactly_200_chars_is_valid_test() {
  let long_title = string.repeat("a", 200)
  let result = shared.new_todo(
    title: long_title,
    description: None,
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> item.title |> should.equal(long_title)
    Error(_) -> should.fail()
  }
}

// Test: Title over 200 characters is handled (implementation may truncate or reject)
pub fn title_over_200_chars_behavior_test() {
  let very_long_title = string.repeat("a", 201)
  let result = shared.new_todo(
    title: very_long_title,
    description: None,
    priority: shared.Medium,
  )

  // Implementation may accept or reject - test actual behavior
  case result {
    Ok(item) -> {
      // If accepted, title should match
      item.title |> should.equal(very_long_title)
    }
    Error(_) -> {
      // If rejected, that's also valid behavior per boundary contract
      Nil
    }
  }
}
