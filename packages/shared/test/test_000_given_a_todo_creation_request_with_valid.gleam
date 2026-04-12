import gleeunit
import gleeunit/should
import shared
import gleam/string
import gleam/option.{Some, None}

pub fn main() {
  gleeunit.main()
}

// Test: Valid todo creation returns structured object with all boundary contract fields
pub fn todo_creation_valid_fields_returns_structured_object_test() {
  let result = shared.new_todo(
    title: "Complete project documentation",
    description: Some("Write comprehensive docs for the API"),
    priority: shared.High,
  )

  case result {
    Ok(item) -> {
      // id: UUID string (non-empty, contains dashes)
      item.id |> string.length() |> should.equal(36)
      item.id |> string.contains("-") |> should.equal(True)

      // title: string matches input
      item.title |> should.equal("Complete project documentation")

      // description: Some("...") preserved
      item.description |> should.equal(Some("Write comprehensive docs for the API"))

      // priority: High preserved
      item.priority |> should.equal(shared.High)

      // completed: boolean defaults to False
      item.completed |> should.equal(False)

      // created_at: ISO8601 string (non-empty, contains T and Z)
      item.created_at |> string.contains("T") |> should.equal(True)
      item.created_at |> string.contains("Z") |> should.equal(True)

      // updated_at: ISO8601 string (matches created_at on creation)
      item.updated_at |> should.equal(item.created_at)
    }
    Error(_) -> should.fail()
  }
}

// Test: Valid todo with minimal fields uses defaults correctly
pub fn todo_creation_minimal_fields_uses_defaults_test() {
  let result = shared.new_todo(
    title: "Simple task",
    description: None,
    priority: shared.Medium,
  )

  case result {
    Ok(item) -> {
      item.title |> should.equal("Simple task")
      item.description |> should.equal(None)
      item.priority |> should.equal(shared.Medium)
      item.completed |> should.equal(False)
      item.id |> should.not_equal("")
      item.created_at |> should.not_equal("")
      item.updated_at |> should.not_equal("")
    }
    Error(_) -> should.fail()
  }
}
