import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import gleam/string
import todo_store
import shared.{Medium, High}

pub fn main() {
  gleeunit.main()
}

// Test: update returns updated todo with same id for existing todo
pub fn update_returns_updated_todo_with_same_id_test() {
  // Given: An existing todo
  let attrs = shared.new_todo_attrs(title: "Original Title", description: None, priority: Medium)
  let assert Ok(created) = todo_store.create(attrs)
  let original_id = created.id
  let original_created_at = created.created_at

  // When: update is called with new attributes
  let update_attrs = shared.new_todo_attrs(title: "Updated Title", description: Some("New description"), priority: High)
  let result = todo_store.update(original_id, update_attrs)

  // Then: Returns updated todo with same id
  case result {
    Ok(updated) -> {
      should.equal(updated.id, original_id)
      should.equal(updated.title, "Updated Title")
      should.equal(updated.description, Some("New description"))
      should.equal(updated.priority, High)
      // created_at should remain unchanged
      should.equal(updated.created_at, original_created_at)
      // updated_at should reflect the update (it's a String in robustness model)
      should.be_true(string.length(updated.updated_at) > 0)
    }
    _ -> should.fail()
  }
}
