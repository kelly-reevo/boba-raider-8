import gleeunit
import gleeunit/should
import shared
import gleam/string
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Test: todo_to_json produces valid JSON string with all boundary contract fields
pub fn todo_to_json_includes_all_boundary_fields_test() {
  let item = shared.Todo(
    id: "550e8400-e29b-41d4-a716-446655440000",
    title: "Test Todo",
    description: Some("Test Description"),
    priority: shared.High,
    completed: True,
    created_at: "2024-01-15T10:30:00Z",
    updated_at: "2024-01-15T11:00:00Z",
  )

  let json_string = shared.todo_to_json(item)
  
  // id: string (UUID format)
  json_string |> string.contains("\"id\":\"550e8400-e29b-41d4-a716-446655440000\"") |> should.equal(True)
  
  // title: string
  json_string |> string.contains("\"title\":\"Test Todo\"") |> should.equal(True)
  
  // description: string
  json_string |> string.contains("\"description\":\"Test Description\"") |> should.equal(True)
  
  // priority: 'low'|'medium'|'high' (serialized as lowercase string)
  json_string |> string.contains("\"priority\":\"high\"") |> should.equal(True)
  
  // completed: boolean
  json_string |> string.contains("\"completed\":true") |> should.equal(True)
  
  // created_at: ISO8601 string
  json_string |> string.contains("\"created_at\":\"2024-01-15T10:30:00Z\"") |> should.equal(True)
  
  // updated_at: ISO8601 string
  json_string |> string.contains("\"updated_at\":\"2024-01-15T11:00:00Z\"") |> should.equal(True)
}

// Test: todo_to_json serializes None description as null
pub fn todo_to_json_serializes_none_description_as_null_test() {
  let item = shared.Todo(
    id: "550e8400-e29b-41d4-a716-446655440001",
    title: "No Description Todo",
    description: None,
    priority: shared.Low,
    completed: False,
    created_at: "2024-01-15T10:30:00Z",
    updated_at: "2024-01-15T10:30:00Z",
  )

  let json_string = shared.todo_to_json(item)
  
  // None description serializes as null per boundary contract
  json_string |> string.contains("\"description\":null") |> should.equal(True)
}

// Test: todo_from_json parses all valid priority enum values correctly
pub fn todo_from_json_priority_enum_values_test() {
  let low_json = "{\"id\":\"550e8400-e29b-41d4-a716-446655440000\",\"title\":\"Low\",\"description\":null,\"priority\":\"low\",\"completed\":false,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T10:30:00Z\"}"
  let medium_json = "{\"id\":\"550e8400-e29b-41d4-a716-446655440001\",\"title\":\"Medium\",\"description\":null,\"priority\":\"medium\",\"completed\":false,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T10:30:00Z\"}"
  let high_json = "{\"id\":\"550e8400-e29b-41d4-a716-446655440002\",\"title\":\"High\",\"description\":null,\"priority\":\"high\",\"completed\":false,\"created_at\":\"2024-01-15T10:30:00Z\",\"updated_at\":\"2024-01-15T10:30:00Z\"}"
  
  case shared.todo_from_json(low_json) {
    Ok(item) -> item.priority |> should.equal(shared.Low)
    Error(_) -> should.fail()
  }

  case shared.todo_from_json(medium_json) {
    Ok(item) -> item.priority |> should.equal(shared.Medium)
    Error(_) -> should.fail()
  }

  case shared.todo_from_json(high_json) {
    Ok(item) -> item.priority |> should.equal(shared.High)
    Error(_) -> should.fail()
  }
}