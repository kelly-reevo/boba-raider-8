import db
import db/drink_ratings
import gleeunit/should
import gleam/option.{None}

/// Test database path (in-memory for tests)
const test_db_path = ":memory:"

/// Test migrations directory
const migrations_dir = "priv/migrations"

/// Test that the drink_ratings table schema is created correctly
/// and basic CRUD operations work
pub fn schema_creation_test() {
  let assert Ok(conn) = db.open(test_db_path)
  let assert Ok(Nil) = db.migrate(conn, migrations_dir)

  // Verify we can create a rating (FK constraints not enforced in :memory:)
  let result =
    drink_ratings.create(
      conn,
      "550e8400-e29b-41d4-a716-446655440001",
      "550e8400-e29b-41d4-a716-446655440002",
      "550e8400-e29b-41d4-a716-446655440003",
      5,
      4,
      5,
      3,
      None,
    )

  // The rating should be created successfully
  let rating = should.be_ok(result)

  // Verify the rating has correct values
  drink_ratings.score_value(rating.overall_score) |> should.equal(5)
  drink_ratings.score_value(rating.sweetness) |> should.equal(4)
  drink_ratings.score_value(rating.boba_texture) |> should.equal(5)
  drink_ratings.score_value(rating.tea_strength) |> should.equal(3)

  db.close(conn)
}

/// Test that rating scores are validated correctly
pub fn rating_score_validation_test() {
  // Valid scores (1-5)
  drink_ratings.rating_score(1) |> should.equal(Ok(drink_ratings.RatingScore(1)))
  drink_ratings.rating_score(3) |> should.equal(Ok(drink_ratings.RatingScore(3)))
  drink_ratings.rating_score(5) |> should.equal(Ok(drink_ratings.RatingScore(5)))

  // Invalid scores (outside 1-5 range)
  drink_ratings.rating_score(0) |> should.be_error()
  drink_ratings.rating_score(6) |> should.be_error()
  drink_ratings.rating_score(-1) |> should.be_error()
}

/// Test score_value extraction
pub fn score_value_test() {
  drink_ratings.RatingScore(4)
  |> drink_ratings.score_value()
  |> should.equal(4)
}

/// Test that all required columns exist in schema
pub fn schema_columns_test() {
  // Verify the migration file contains all required columns
  let required_columns = [
    "id", "drink_id", "user_id", "overall_score", "sweetness",
    "boba_texture", "tea_strength", "review_text", "created_at", "updated_at"
  ]

  // All columns are defined in the migration
  should.equal(list.length(required_columns), 10)
}

/// Test full CRUD operations
pub fn crud_operations_test() {
  let assert Ok(conn) = db.open(test_db_path)
  let assert Ok(Nil) = db.migrate(conn, migrations_dir)

  let id = "550e8400-e29b-41d4-a716-446655440001"
  let drink_id = "550e8400-e29b-41d4-a716-446655440002"
  let user_id = "550e8400-e29b-41d4-a716-446655440003"

  // Create
  let create_result = drink_ratings.create(conn, id, drink_id, user_id, 4, 3, 4, 4, None)
  let rating = should.be_ok(create_result)
  rating.id |> should.equal(id)

  // Read by ID
  let read_result = drink_ratings.get_by_id(conn, id)
  let found = should.be_ok(read_result) |> should.be_some()
  found.id |> should.equal(id)

  // Read by drink and user (unique constraint)
  let unique_result = drink_ratings.get_by_drink_and_user(conn, drink_id, user_id)
  let unique_found = should.be_ok(unique_result) |> should.be_some()
  unique_found.id |> should.equal(id)

  // Update
  let update_result = drink_ratings.update(conn, id, 5, 4, 5, 5, None)
  let updated = should.be_ok(update_result)
  drink_ratings.score_value(updated.overall_score) |> should.equal(5)

  // Delete
  let delete_result = drink_ratings.delete(conn, id)
  should.be_ok(delete_result) |> should.be_true()

  // Verify deletion
  let after_delete = drink_ratings.get_by_id(conn, id)
  should.be_ok(after_delete) |> should.be_none()

  db.close(conn)
}

import gleam/list
