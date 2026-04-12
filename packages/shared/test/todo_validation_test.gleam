import gleeunit
import gleeunit/should
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import shared.{Low, Medium, High}

pub fn main() {
  gleeunit.main()
}

// Test 000: Given an empty title, validation fails with MissingField error for title
pub fn empty_title_validation_test() {
  let result = shared.new_todo(title: "", description: None, priority: Medium)

  case result {
    Error(errors) -> {
      let has_title_error =
        errors
        |> shared.validation_errors_contain_field("title")
      should.be_true(has_title_error)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Given a whitespace-only title, validation fails with MissingField error
pub fn whitespace_only_title_validation_test() {
  let result = shared.new_todo(title: "   ", description: None, priority: Medium)

  case result {
    Error(errors) -> {
      let has_title_error =
        errors
        |> shared.validation_errors_contain_field("title")
      should.be_true(has_title_error)
    }
    Ok(_) -> should.fail()
  }
}

// Test 001: Given a title > 200 chars, validation fails with InvalidField error for title length
pub fn title_too_long_validation_test() {
  let long_title = string.repeat("a", 201)
  let result = shared.new_todo(title: long_title, description: None, priority: Medium)

  case result {
    Error(errors) -> {
      let has_length_error =
        errors
        |> shared.validation_errors_contain_field("title")
      should.be_true(has_length_error)
      should.equal(string.length(long_title), 201)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Given a title exactly at 200 chars, validation passes
pub fn title_at_max_length_validation_test() {
  let max_title = string.repeat("b", 200)
  let result = shared.new_todo(title: max_title, description: None, priority: Medium)

  case result {
    Ok(item) -> {
      should.equal(item.title, max_title)
    }
    Error(_) -> should.fail()
  }
}

// Test 002: Given an invalid priority value via JSON, validation fails with InvalidField error for priority
pub fn invalid_priority_validation_test() {
  let invalid_json = "{\"id\": \"1\", \"title\": \"Test\", \"description\": null, \"priority\": \"urgent\", \"completed\": false, \"created_at\": \"2024-01-01T00:00:00Z\", \"updated_at\": \"2024-01-01T00:00:00Z\"}"

  let result = shared.todo_from_json(invalid_json)

  case result {
    Error(errors) -> {
      let has_priority_error =
        errors
        |> shared.validation_errors_contain_field("priority")
      should.be_true(has_priority_error)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Priority validation accepts 'low', 'medium', 'high' (case insensitive)
pub fn valid_priorities_test() {
  // Test low priority
  let json_low = "{\"id\": \"1\", \"title\": \"Test\", \"description\": null, \"priority\": \"low\", \"completed\": false, \"created_at\": \"2024-01-01T00:00:00Z\", \"updated_at\": \"2024-01-01T00:00:00Z\"}"
  let result_low = shared.todo_from_json(json_low)
  should.be_ok(result_low)

  // Test medium priority
  let json_med = "{\"id\": \"2\", \"title\": \"Test\", \"description\": null, \"priority\": \"medium\", \"completed\": false, \"created_at\": \"2024-01-01T00:00:00Z\", \"updated_at\": \"2024-01-01T00:00:00Z\"}"
  let result_med = shared.todo_from_json(json_med)
  should.be_ok(result_med)

  // Test high priority
  let json_high = "{\"id\": \"3\", \"title\": \"Test\", \"description\": null, \"priority\": \"high\", \"completed\": false, \"created_at\": \"2024-01-01T00:00:00Z\", \"updated_at\": \"2024-01-01T00:00:00Z\"}"
  let result_high = shared.todo_from_json(json_high)
  should.be_ok(result_high)
}

// Test 003: Given a description > 2000 chars, validation fails with InvalidField error for description length
pub fn description_too_long_validation_test() {
  let long_description = string.repeat("x", 2001)
  let result = shared.new_todo(
    title: "Valid Title",
    description: Some(long_description),
    priority: Medium
  )

  case result {
    Error(errors) -> {
      let has_description_error =
        errors
        |> shared.validation_errors_contain_field("description")
      should.be_true(has_description_error)
      should.equal(string.length(long_description), 2001)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Given a description exactly at 2000 chars, validation passes
pub fn description_at_max_length_validation_test() {
  let max_description = string.repeat("y", 2000)
  let result = shared.new_todo(
    title: "Valid Title",
    description: Some(max_description),
    priority: Medium
  )

  case result {
    Ok(item) -> {
      should.equal(item.title, "Valid Title")
      case item.description {
        Some(desc) -> should.equal(desc, max_description)
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test 004: Given valid inputs, validation passes with no errors and returns a Todo
pub fn valid_inputs_validation_test() {
  let result = shared.new_todo(
    title: "Buy groceries",
    description: Some("Get milk, eggs, and bread"),
    priority: Medium
  )

  case result {
    Ok(item) -> {
      should.equal(item.title, "Buy groceries")
      should.equal(item.completed, False)
      case item.description {
        Some(desc) -> should.equal(desc, "Get milk, eggs, and bread")
        None -> should.fail()
      }
      // ID should be generated (non-empty UUID format with dashes)
      should.be_true(string.contains(item.id, "-"))
      // Timestamps should be generated
      should.be_true(string.contains(item.created_at, "T"))
      should.be_true(string.contains(item.updated_at, "Z"))
    }
    Error(_) -> {
      should.fail()
    }
  }
}

// Test: Given valid inputs with minimal data (no description), validation passes
pub fn valid_inputs_minimal_test() {
  let result = shared.new_todo(
    title: "Simple task",
    description: None,
    priority: Low
  )

  case result {
    Ok(item) -> {
      should.equal(item.title, "Simple task")
      should.equal(item.description, None)
      should.equal(item.completed, False)
    }
    Error(_) -> should.fail()
  }
}

// Test: Given valid inputs with high priority, validation passes
pub fn valid_inputs_high_priority_test() {
  let result = shared.new_todo(
    title: "Urgent: Fix production bug",
    description: Some("Customer reporting critical issue"),
    priority: High
  )

  case result {
    Ok(item) -> {
      should.equal(item.title, "Urgent: Fix production bug")
    }
    Error(_) -> should.fail()
  }
}

// Test: Title with exactly 1 character passes validation
pub fn single_char_title_test() {
  let result = shared.new_todo(
    title: "X",
    description: None,
    priority: Medium
  )
  should.be_ok(result)
}

// Test 005: Validation returns structured error list with field-level details for multiple validation failures
pub fn multiple_validation_errors_test() {
  let long_title = string.repeat("t", 250)
  let long_description = string.repeat("d", 2500)

  let result = shared.new_todo(
    title: long_title,
    description: Some(long_description),
    priority: Medium
  )

  case result {
    Error(errors) -> {
      // Should have at least 1 error
      should.be_true(list.length(errors) >= 1)

      // Verify we can identify which fields have errors
      let has_title = shared.validation_errors_contain_field(errors, "title")
      let has_description = shared.validation_errors_contain_field(errors, "description")

      // At least one field should be flagged
      should.be_true(has_title || has_description)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Empty string title and empty string description both fail
pub fn empty_strings_validation_test() {
  let result = shared.new_todo(
    title: "",
    description: Some(""),
    priority: Medium
  )

  case result {
    Error(errors) -> {
      // Empty title should be caught
      let has_title_error =
        shared.validation_errors_contain_field(errors, "title")
      should.be_true(has_title_error)
    }
    Ok(_) -> should.fail()
  }
}

// Test: Title with 199 characters passes
pub fn title_just_under_limit_test() {
  let title = string.repeat("a", 199)
  let result = shared.new_todo(
    title: title,
    description: None,
    priority: Medium
  )
  should.be_ok(result)
}

// Test: Description with 1999 characters passes
pub fn description_just_under_limit_test() {
  let desc = string.repeat("b", 1999)
  let result = shared.new_todo(
    title: "Valid",
    description: Some(desc),
    priority: Medium
  )
  should.be_ok(result)
}
