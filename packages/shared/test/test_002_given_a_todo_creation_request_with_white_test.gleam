import gleeunit/should
import shared
import gleam/option.{None}

// Given a todo creation request with whitespace-only title, when validated, then validation fails
pub fn todo_creation_with_whitespace_title_fails_validation_test() {
  let result = shared.new_todo(
    title: "   ",
    description: None,
    priority: shared.Medium,
  )
  
  // Should return Error - whitespace-only titles are treated as empty
  case result {
    Error(errors) -> {
      case errors {
        [shared.MissingField("title")] -> Nil
        _ -> panic as "Expected MissingField error for whitespace title"
      }
    }
    Ok(_) -> panic as "Expected validation to fail for whitespace-only title"
  }
}
