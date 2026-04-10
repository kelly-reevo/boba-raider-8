import gleam/option.{type Option, None, Some}
import gleam/string
import gleeunit/should
import rating_store
import shared

/// Test that rating store can be started
pub fn rating_store_start_test() {
  let result = rating_store.start()
  should.be_ok(result)

  // Clean up
  let assert Ok(store) = result
  rating_store.stop(store)
}

/// Test creating a rating
pub fn create_rating_test() {
  let assert Ok(store) = rating_store.start()

  let rating = shared.Rating(
    id: "rating_1",
    drink_id: "drink_1",
    user_id: "user_1",
    scores: shared.RatingScores(
      overall_score: 5,
      sweetness: 3,
      boba_texture: 4,
      tea_strength: 5,
    ),
    review_text: Some("Amazing boba!"),
    created_at: "1234567890",
    updated_at: "1234567890",
  )

  let result = rating_store.create_rating(store, rating)
  should.be_ok(result)

  // Clean up
  rating_store.stop(store)
}

/// Test duplicate rating prevention
pub fn duplicate_rating_test() {
  let assert Ok(store) = rating_store.start()

  let rating = shared.Rating(
    id: "rating_1",
    drink_id: "drink_1",
    user_id: "user_1",
    scores: shared.RatingScores(
      overall_score: 5,
      sweetness: 3,
      boba_texture: 4,
      tea_strength: 5,
    ),
    review_text: None,
    created_at: "1234567890",
    updated_at: "1234567890",
  )

  // First creation should succeed
  let first = rating_store.create_rating(store, rating)
  should.be_ok(first)

  // Second creation for same drink/user should fail with DuplicateRating
  let second = rating_store.create_rating(store, rating)
  should.equal(second, Error(shared.DuplicateRating))

  // Clean up
  rating_store.stop(store)
}

/// Test rating retrieval
pub fn get_rating_test() {
  let assert Ok(store) = rating_store.start()

  let rating = shared.Rating(
    id: "rating_1",
    drink_id: "drink_1",
    user_id: "user_1",
    scores: shared.RatingScores(
      overall_score: 4,
      sweetness: 4,
      boba_texture: 4,
      tea_strength: 4,
    ),
    review_text: None,
    created_at: "1234567890",
    updated_at: "1234567890",
    )

  // Create rating
  let _ = rating_store.create_rating(store, rating)

  // Retrieve rating
  let retrieved = rating_store.get_by_drink_and_user(store, "drink_1", "user_1")
  should.be_some(retrieved)

  // Non-existent rating
  let not_found = rating_store.get_by_drink_and_user(store, "drink_2", "user_1")
  should.be_none(not_found)

  // Clean up
  rating_store.stop(store)
}

/// Test input validation
pub fn validate_scores_test() {
  let valid_input = shared.CreateRatingInput(
    overall_score: 5,
    sweetness: 3,
    boba_texture: 4,
    tea_strength: 2,
    review_text: Some("Great drink!"),
  )
  should.be_ok(shared.validate_scores(valid_input))

  let invalid_overall = shared.CreateRatingInput(
    overall_score: 0,
    sweetness: 3,
    boba_texture: 4,
    tea_strength: 2,
    review_text: None,
  )
  should.be_error(shared.validate_scores(invalid_overall))

  let invalid_sweetness = shared.CreateRatingInput(
    overall_score: 3,
    sweetness: 6,
    boba_texture: 4,
    tea_strength: 2,
    review_text: None,
  )
  should.be_error(shared.validate_scores(invalid_sweetness))
}

/// Test review text validation
pub fn validate_review_test() {
  let long_review = string.repeat("a", 1001)

  let invalid_review = shared.CreateRatingInput(
    overall_score: 5,
    sweetness: 3,
    boba_texture: 4,
    tea_strength: 5,
    review_text: Some(long_review),
  )

  should.be_false(shared.is_valid_review_text(invalid_review.review_text))

  let valid_review = shared.CreateRatingInput(
    overall_score: 5,
    sweetness: 3,
    boba_texture: 4,
    tea_strength: 5,
    review_text: Some(string.repeat("a", 1000)),
  )

  should.be_true(shared.is_valid_review_text(valid_review.review_text))
}
