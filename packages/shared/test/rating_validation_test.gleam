import gleeunit
import gleeunit/should
import gleam/string
import rating_validation

pub fn main() {
  gleeunit.main()
}

// Test 000: missing overall_rating returns required error
pub fn validate_missing_overall_rating_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "overall_rating", message: "overall_rating is required"),
  ]))
}

// Test 001: overall_rating 0 returns out of range error
pub fn validate_overall_rating_zero_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "0"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "overall_rating", message: "overall_rating must be between 1 and 5"),
  ]))
}

// Test 002: overall_rating 6 returns out of range error
pub fn validate_overall_rating_six_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "6"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "overall_rating", message: "overall_rating must be between 1 and 5"),
  ]))
}

// Test 003: sweetness 0 returns out of range error
pub fn validate_sweetness_zero_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "0"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "sweetness", message: "sweetness must be between 1 and 10"),
  ]))
}

// Test 004: sweetness 11 returns out of range error
pub fn validate_sweetness_eleven_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "11"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "sweetness", message: "sweetness must be between 1 and 10"),
  ]))
}

// Test 005: boba_texture 0 returns out of range error
pub fn validate_boba_texture_zero_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "0"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "boba_texture", message: "boba_texture must be between 1 and 10"),
  ]))
}

// Test 006: boba_texture 11 returns out of range error
pub fn validate_boba_texture_eleven_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "11"),
    #("tea_strength", "6"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "boba_texture", message: "boba_texture must be between 1 and 10"),
  ]))
}

// Test 007: tea_strength 0 returns out of range error
pub fn validate_tea_strength_zero_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "0"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "tea_strength", message: "tea_strength must be between 1 and 10"),
  ]))
}

// Test 008: tea_strength 11 returns out of range error
pub fn validate_tea_strength_eleven_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "11"),
    #("review_text", "Great drink!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "tea_strength", message: "tea_strength must be between 1 and 10"),
  ]))
}

// Test 009: review_text with 2001 characters returns max length error
pub fn validate_review_text_too_long_test() {
  let long_text = string.repeat("a", 2001)
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", long_text),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Invalid([
    rating_validation.Error(field: "review_text", message: "review_text must be at most 2000 characters"),
  ]))
}

// Test 010: valid rating at boundaries returns Valid
pub fn validate_valid_rating_test() {
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "5"),
    #("sweetness", "10"),
    #("boba_texture", "1"),
    #("tea_strength", "5"),
    #("review_text", "Perfect balance of flavors!"),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Valid)
}

// Test 011: review_text at exactly 2000 characters returns Valid
pub fn validate_review_text_at_max_length_test() {
  let max_text = string.repeat("a", 2000)
  let input = [
    #("drink_id", "550e8400-e29b-41d4-a716-446655440000"),
    #("overall_rating", "4"),
    #("sweetness", "5"),
    #("boba_texture", "7"),
    #("tea_strength", "6"),
    #("review_text", max_text),
  ]

  let result = rating_validation.validate(input)

  should.equal(result, rating_validation.Valid)
}
