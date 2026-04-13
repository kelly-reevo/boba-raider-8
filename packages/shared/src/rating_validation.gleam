import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type ValidationResult {
  Valid
  Invalid(errors: List(Error))
}

pub type Error {
  Error(field: String, message: String)
}

pub fn validate(input: List(#(String, String))) -> ValidationResult {
  let errors = []

  // Validate overall_rating (required, range 1-5)
  let overall_rating_val = result.unwrap(list.key_find(input, "overall_rating"), "")
  let errors = case overall_rating_val {
    "" -> [Error("overall_rating", "overall_rating is required"), ..errors]
    value ->
      case result.unwrap(int.parse(value), -1) {
        int_val if int_val >= 1 && int_val <= 5 -> errors
        _ -> [Error("overall_rating", "overall_rating must be between 1 and 5"), ..errors]
      }
  }

  // Validate sweetness (optional, but if present must be 1-10)
  let sweetness_val = result.unwrap(list.key_find(input, "sweetness"), "")
  let errors = case sweetness_val {
    "" -> errors
    value ->
      case result.unwrap(int.parse(value), -1) {
        int_val if int_val >= 1 && int_val <= 10 -> errors
        _ -> [Error("sweetness", "sweetness must be between 1 and 10"), ..errors]
      }
  }

  // Validate boba_texture (optional, but if present must be 1-10)
  let boba_texture_val = result.unwrap(list.key_find(input, "boba_texture"), "")
  let errors = case boba_texture_val {
    "" -> errors
    value ->
      case result.unwrap(int.parse(value), -1) {
        int_val if int_val >= 1 && int_val <= 10 -> errors
        _ -> [Error("boba_texture", "boba_texture must be between 1 and 10"), ..errors]
      }
  }

  // Validate tea_strength (optional, but if present must be 1-10)
  let tea_strength_val = result.unwrap(list.key_find(input, "tea_strength"), "")
  let errors = case tea_strength_val {
    "" -> errors
    value ->
      case result.unwrap(int.parse(value), -1) {
        int_val if int_val >= 1 && int_val <= 10 -> errors
        _ -> [Error("tea_strength", "tea_strength must be between 1 and 10"), ..errors]
      }
  }

  // Validate review_text (optional, but if present must be <= 2000 chars)
  let review_text_val = result.unwrap(list.key_find(input, "review_text"), "")
  let errors = case review_text_val {
    "" -> errors
    value ->
      case string.length(value) <= 2000 {
        True -> errors
        False -> [Error("review_text", "review_text must be at most 2000 characters"), ..errors]
      }
  }

  case errors {
    [] -> Valid
    _ -> Invalid(list.reverse(errors))
  }
}
