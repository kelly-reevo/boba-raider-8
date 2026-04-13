import gleeunit/should
import shared
import gleam/option.{None}
import gleam/string

// Given a Todo with None description, when serialized to JSON, then description is null
pub fn todo_to_json_null_description_test() {
  let todo_result = shared.new_todo(
    title: "No Description Todo",
    description: None,
    priority: shared.Medium,
  )

  case todo_result {
    Ok(the_todo) -> {
      let json_string = shared.todo_to_json(the_todo)

      // Should contain description as null
      should.be_true(string.contains(json_string, "\"description\":null"))
    }
    Error(_) -> panic as "Expected successful todo creation"
  }
}
