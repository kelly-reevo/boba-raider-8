import gleeunit
import gleeunit/should
import todo_actor

// Verify not-found indicator for various non-existent id formats

pub fn main() {
  gleeunit.main()
}

pub fn read_random_uuid_returns_not_found_test() {
  // Arrange
  let assert Ok(actor_pid) = todo_actor.start()
  let random_uuid = "550e8400-e29b-41d4-a716-446655440000"

  // Act
  let result = todo_actor.read(actor_pid, random_uuid)

  // Assert: Error variant indicating not found
  should.be_error(result)
  let assert Error(err) = result
  should.equal(err, "not_found")

  todo_actor.shutdown(actor_pid)
}

pub fn read_after_delete_returns_not_found_test() {
  // Arrange: Create then delete a todo
  let assert Ok(actor_pid) = todo_actor.start()
  let assert Ok(created) = todo_actor.create(actor_pid, "To Delete", "", "low")
  let id_to_delete = created.id
  let assert Ok(_) = todo_actor.delete(actor_pid, id_to_delete)

  // Act: Try to read the deleted todo
  let result = todo_actor.read(actor_pid, id_to_delete)

  // Assert: Previously existing id now returns not-found
  should.be_error(result)
  let assert Error(err) = result
  should.equal(err, "not_found")

  todo_actor.shutdown(actor_pid)
}
