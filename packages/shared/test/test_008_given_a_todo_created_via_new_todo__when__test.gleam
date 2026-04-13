import gleeunit/should
import shared
import gleam/option.{None}
import gleam/string

// Given a newly created todo, when checking defaults, then completed is false and id/timestamps are set
pub fn todo_creation_sets_default_fields_test() {
  let result = shared.new_todo(
    title: "Default Fields Todo",
    description: None,
    priority: shared.Medium,
  )
  
  case result {
    Ok(the_todo) -> {
      // completed should default to false
      the_todo.completed |> should.equal(False)
      
      // id should be a non-empty string
      should.be_true(string.length(the_todo.id) > 0)
      
      // created_at should be a non-empty string (ISO8601 format)
      should.be_true(string.length(the_todo.created_at) > 0)
      
      // updated_at should be a non-empty string (ISO8601 format)
      should.be_true(string.length(the_todo.updated_at) > 0)
    }
    Error(_) -> panic as "Expected successful creation"
  }
}

