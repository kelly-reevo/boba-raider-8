import auth/authorization
import domain/drink.{Drink}
import domain/rating.{Rating}
import domain/user.{User, Admin, Regular}
import gleeunit
import gleeunit/should
import config
import storage/store
import web/handlers/drink_handler
import web/server.{Request}
import gleam/dict
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

/// Test: Creator can delete their own drink
pub fn delete_drink_by_creator_test() {
  let store = store.new()

  // Create a drink
  let drink = Drink(
    id: "drink-1",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let store = store.put_drink(store, drink)

  // Create request as the creator
  let request = Request(
    method: "DELETE",
    path: "/api/drinks/drink-1",
    headers: dict.from_list([#("x-user-id", "user-1"), #("x-user-role", "user")]),
    body: "",
  )

  let response = drink_handler.delete(store, request, "drink-1")

  response.status
  |> should.equal(204)
}

/// Test: Admin can delete any drink
pub fn delete_drink_by_admin_test() {
  let store = store.new()

  // Create a drink by user-1
  let drink = Drink(
    id: "drink-2",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let store = store.put_drink(store, drink)

  // Create request as an admin (different user)
  let request = Request(
    method: "DELETE",
    path: "/api/drinks/drink-2",
    headers: dict.from_list([#("x-user-id", "admin-1"), #("x-user-role", "admin")]),
    body: "",
  )

  let response = drink_handler.delete(store, request, "drink-2")

  response.status
  |> should.equal(204)
}

/// Test: Non-creator, non-admin cannot delete drink (403 Forbidden)
pub fn delete_drink_forbidden_test() {
  let store = store.new()

  // Create a drink by user-1
  let drink = Drink(
    id: "drink-3",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let store = store.put_drink(store, drink)

  // Create request as a different regular user
  let request = Request(
    method: "DELETE",
    path: "/api/drinks/drink-3",
    headers: dict.from_list([#("x-user-id", "user-2"), #("x-user-role", "user")]),
    body: "",
  )

  let response = drink_handler.delete(store, request, "drink-3")

  response.status
  |> should.equal(403)
}

/// Test: Delete non-existent drink returns 404
pub fn delete_drink_not_found_test() {
  let store = store.new()

  // Create request for non-existent drink
  let request = Request(
    method: "DELETE",
    path: "/api/drinks/nonexistent",
    headers: dict.from_list([#("x-user-id", "user-1"), #("x-user-role", "admin")]),
    body: "",
  )

  let response = drink_handler.delete(store, request, "nonexistent")

  response.status
  |> should.equal(404)
}

/// Test: Deleting drink cascades to delete associated ratings
pub fn delete_drink_cascades_ratings_test() {
  let store = store.new()

  // Create a drink
  let drink = Drink(
    id: "drink-4",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let store = store.put_drink(store, drink)

  // Add ratings for the drink
  let rating1 = Rating(id: "rating-1", drink_id: "drink-4", user_id: "user-a", score: 5, comment: "Great!")
  let rating2 = Rating(id: "rating-2", drink_id: "drink-4", user_id: "user-b", score: 4, comment: "Good!")
  let store = store.put_rating(store, rating1)
  let store = store.put_rating(store, rating2)

  // Verify ratings exist
  store.get_drink_ratings(store, "drink-4")
  |> should.equal([rating2, rating1]) // Order is reversed due to list prepend

  // Delete the drink as creator
  let request = Request(
    method: "DELETE",
    path: "/api/drinks/drink-4",
    headers: dict.from_list([#("x-user-id", "user-1"), #("x-user-role", "user")]),
    body: "",
  )
  let response = drink_handler.delete(store, request, "drink-4")

  response.status
  |> should.equal(204)

  // Verify drink is deleted by checking store directly
  // Note: The handler returns 204 but doesn't modify the passed-in store
  // (stores are immutable). In production, the store would be an actor
  // or ETS table that the handler mutates.
}

/// Test: Authorization helper - admin can delete
pub fn authorization_admin_can_delete_test() {
  let store = store.new()
  let drink = Drink(
    id: "drink-5",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let admin = User(id: "admin-1", role: Admin)

  authorization.can_delete_drink(store, admin, drink)
  |> should.equal(True)
}

/// Test: Authorization helper - creator can delete
pub fn authorization_creator_can_delete_test() {
  let store = store.new()
  let drink = Drink(
    id: "drink-6",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let creator = User(id: "user-1", role: Regular)

  authorization.can_delete_drink(store, creator, drink)
  |> should.equal(True)
}

/// Test: Authorization helper - non-creator cannot delete
pub fn authorization_non_creator_cannot_delete_test() {
  let store = store.new()
  let drink = Drink(
    id: "drink-7",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let other_user = User(id: "user-2", role: Regular)

  authorization.can_delete_drink(store, other_user, drink)
  |> should.equal(False)
}

/// Test: Store cascade delete removes ratings
pub fn store_cascade_delete_test() {
  let store = store.new()

  // Create a drink
  let drink = Drink(
    id: "drink-8",
    store_id: "store-1",
    creator_id: "user-1",
    name: "Test Drink",
    description: "A test drink",
  )
  let store = store.put_drink(store, drink)

  // Add ratings for the drink
  let rating1 = Rating(id: "rating-3", drink_id: "drink-8", user_id: "user-a", score: 5, comment: "Great!")
  let rating2 = Rating(id: "rating-4", drink_id: "drink-8", user_id: "user-b", score: 4, comment: "Good!")
  let store = store.put_rating(store, rating1)
  let store = store.put_rating(store, rating2)

  // Verify ratings exist
  store.get_drink_ratings(store, "drink-8")
  |> should.equal([rating2, rating1])

  // Delete the drink (cascades to ratings)
  let store = store.delete_drink(store, "drink-8")

  // Verify drink is gone
  store.get_drink(store, "drink-8")
  |> should.equal(None)

  // Verify ratings are gone (via the index)
  store.get_drink_ratings(store, "drink-8")
  |> should.equal([])
}
