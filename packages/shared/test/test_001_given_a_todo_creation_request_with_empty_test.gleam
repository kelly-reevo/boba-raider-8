import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request with empty title, when validated, then validation fails with error 'title is required'
pub fn todo_creation_with_empty_title_fails_validation_test() {
  let result = shared.new_todo(
    title: "",
    description: None,
    priority: shared.Medium,
  )
  
  // Should return Error with MissingField("title")
  case result {
    Error(errors) -> {
      case errors {
        [shared.MissingField("title")] -> Nil
        _ -> panic
      }
    }
    Ok(_) -> panic as "Expected validation to fail for empty title"
  }
}

// Helper function for string inspection


fn inspect(value: a) -> String {
  "inspect"
}