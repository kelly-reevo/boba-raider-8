import gleeunit/should
import shared
import gleam/option.{None, Some}
import gleam/string
import gleam/list

// Test 000: Given a new todo creation with valid title, then all required fields are present
pub fn todo_creation_required_fields_present_test() {
  let result = shared.new_todo(title: "Test Todo", description: None, priority: shared.Medium)

  case result {
    Ok(t) -> {
      // id: string (UUID v4)
      {string.length(t.id) > 0} |> should.be_true()

      // title: string (1-200 chars)
      t.title |> should.equal("Test Todo")

      // priority: 'low' | 'medium' | 'high'
      t.priority |> should.equal(shared.Medium)

      // completed: boolean (default false)
      t.completed |> should.be_false()

      // created_at: string (ISO8601)
      {string.length(t.created_at) > 0} |> should.be_true()

      // updated_at: string (ISO8601)
      {string.length(t.updated_at) > 0} |> should.be_true()
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 001: Given a todo with optional description provided, then description field contains the value
pub fn todo_creation_with_optional_description_test() {
  let result = shared.new_todo(
    title: "Test Todo",
    description: Some("This is a description"),
    priority: shared.Low
  )

  case result {
    Ok(t) -> {
      case t.description {
        Some(desc) -> desc |> should.equal("This is a description")
        None -> {
          should.fail()
          Nil
        }
      }
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 002: Given a todo without description, then description field is None
pub fn todo_creation_without_description_has_none_test() {
  let result = shared.new_todo(
    title: "Test Todo",
    description: None,
    priority: shared.High
  )

  case result {
    Ok(t) -> {
      t.description |> should.equal(None)
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 003: Given server-side generation, id is auto-populated as UUID v4 format
pub fn todo_server_generated_id_is_uuid_v4_test() {
  let result = shared.new_todo(title: "Test", description: None, priority: shared.Medium)

  case result {
    Ok(t) -> {
      // UUID v4 format: 8-4-4-4-12 hexadecimal characters
      string.length(t.id) |> should.equal(36)
      string.contains(t.id, "-") |> should.be_true()
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 004: Given server-side generation, created_at and updated_at are auto-populated as ISO8601 timestamps
pub fn todo_server_generated_timestamps_are_iso8601_test() {
  let result = shared.new_todo(title: "Test", description: None, priority: shared.Medium)

  case result {
    Ok(t) -> {
      // ISO8601 format: YYYY-MM-DDTHH:MM:SSZ
      {string.length(t.created_at) > 0} |> should.be_true()
      {string.length(t.updated_at) > 0} |> should.be_true()

      // Should contain ISO8601 separators
      string.contains(t.created_at, "T") |> should.be_true()
      string.contains(t.created_at, ":") |> should.be_true()

      // created_at and updated_at should be equal on initial creation
      t.created_at |> should.equal(t.updated_at)
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 005: Given empty title, validation returns error for missing required field
pub fn todo_validation_empty_title_fails_test() {
  let result = shared.new_todo(title: "", description: None, priority: shared.Medium)

  case result {
    Ok(_) -> {
      should.fail()
      Nil
    }
    Error(errors) -> {
      // Should have at least one validation error
      {list.length(errors) > 0} |> should.be_true()
      Nil
    }
  }
}

// Test 006: Given title exceeding 200 chars, validation returns error
pub fn todo_validation_title_over_200_chars_fails_test() {
  let long_title = string.repeat("a", 201)
  let result = shared.new_todo(title: long_title, description: None, priority: shared.Medium)

  case result {
    Ok(_) -> {
      should.fail()
      Nil
    }
    Error(_) -> Nil // Expected - validation should fail
  }
}

// Test 007: Given description exceeding 2000 chars, validation returns error
pub fn todo_validation_description_over_2000_chars_fails_test() {
  let long_description = string.repeat("b", 2001)
  let result = shared.new_todo(
    title: "Valid Title",
    description: Some(long_description),
    priority: shared.Medium
  )

  case result {
    Ok(_) -> {
      should.fail()
      Nil
    }
    Error(_) -> Nil // Expected - validation should fail
  }
}

// Test 008: Given JSON serialization, all boundary contract fields are present with correct types
pub fn todo_json_serialization_boundary_contract_test() {
  let result = shared.new_todo(
    title: "JSON Test",
    description: Some("Description"),
    priority: shared.High
  )

  case result {
    Ok(t) -> {
      let json_str = shared.todo_to_json(t)

      // All boundary contract fields must be present in JSON
      string.contains(json_str, "\"id\"") |> should.be_true()
      string.contains(json_str, "\"title\":\"JSON Test\"") |> should.be_true()
      string.contains(json_str, "\"description\":\"Description\"") |> should.be_true()
      string.contains(json_str, "\"priority\":\"high\"") |> should.be_true()
      string.contains(json_str, "\"completed\":false") |> should.be_true()
      string.contains(json_str, "\"created_at\"") |> should.be_true()
      string.contains(json_str, "\"updated_at\"") |> should.be_true()
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 009: Given JSON serialization with None description, field is null
pub fn todo_json_null_description_boundary_contract_test() {
  let result = shared.new_todo(
    title: "No Description Test",
    description: None,
    priority: shared.Low
  )

  case result {
    Ok(t) -> {
      let json_str = shared.todo_to_json(t)

      // description: string | null - should be null when None
      string.contains(json_str, "\"description\":null") |> should.be_true()
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 010: Given JSON deserialization, valid JSON produces Todo with all fields
pub fn todo_json_deserialization_boundary_contract_test() {
  let json_input = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Deserialized\",\"description\":\"Test desc\",\"priority\":\"medium\",\"completed\":true,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T11:00:00Z\"}"

  let result = shared.todo_from_json(json_input)

  case result {
    Ok(t) -> {
      t.id |> should.equal("550e8400-e29b-41d4-a716-446655440000")
      t.title |> should.equal("Deserialized")

      case t.description {
        Some(desc) -> desc |> should.equal("Test desc")
        None -> {
          should.fail()
          Nil
        }
      }

      t.priority |> should.equal(shared.Medium)
      t.completed |> should.be_true()
      t.created_at |> should.equal("2024-01-15T10:30:00Z")
      t.updated_at |> should.equal("2024-01-15T11:00:00Z")
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 011: Given JSON deserialization with null description, produces Todo with None description
pub fn todo_json_deserialization_null_description_test() {
  let json_input = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"No Desc\",\"description\":null,\"priority\":\"low\",\"completed\":false,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T10:30:00Z\"}"

  let result = shared.todo_from_json(json_input)

  case result {
    Ok(t) -> {
      t.description |> should.equal(None)
      t.priority |> should.equal(shared.Low)
      Nil
    }
    Error(_) -> {
      should.fail()
      Nil
    }
  }
}

// Test 012: Given all priority enum values, each is accepted and stored correctly
pub fn todo_priority_enum_values_test() {
  let low_result = shared.new_todo(title: "Low", description: None, priority: shared.Low)
  let medium_result = shared.new_todo(title: "Medium", description: None, priority: shared.Medium)
  let high_result = shared.new_todo(title: "High", description: None, priority: shared.High)

  case low_result {
    Ok(t) -> t.priority |> should.equal(shared.Low)
    Error(_) -> should.fail()
  }

  case medium_result {
    Ok(t) -> t.priority |> should.equal(shared.Medium)
    Error(_) -> should.fail()
  }

  case high_result {
    Ok(t) -> t.priority |> should.equal(shared.High)
    Error(_) -> should.fail()
  }
}
