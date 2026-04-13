import gleeunit/should
import shared
import gleam/option.{Some, None}
import gleam/json
import gleam/string

// Given a Todo, when serialized via todo_to_json, then output contains all required boundary contract fields
pub fn todo_to_json_outputs_correct_structure_test() {
  let todo_result = shared.new_todo(
    title: "JSON Test Todo",
    description: Some("A description"),
    priority: shared.High,
  )

  case todo_result {
    Ok(the_todo) -> {
      let json_string = shared.todo_to_json(the_todo)

      // Verify all boundary contract fields are present:
      // id (string), title (string), description (string|null), priority ('low'|'medium'|'high'),
      // completed (boolean), created_at (string), updated_at (string)

      // Should contain id as string
      should.be_true(string.contains(json_string, "\"id\":\""))

      // Should contain title as string
      should.be_true(string.contains(json_string, "\"title\":\"JSON Test Todo\""))

      // Should contain description as string
      should.be_true(string.contains(json_string, "\"description\":\"A description\""))

      // Should contain priority as string 'high'
      should.be_true(string.contains(json_string, "\"priority\":\"high\""))

      // Should contain completed as boolean
      should.be_true(string.contains(json_string, "\"completed\":false"))

      // Should contain created_at as string
      should.be_true(string.contains(json_string, "\"created_at\":\""))

      // Should contain updated_at as string
      should.be_true(string.contains(json_string, "\"updated_at\":\""))
    }
    Error(_) -> panic as "Expected successful todo creation"
  }
}
