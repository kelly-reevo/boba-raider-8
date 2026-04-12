/// Test helpers for web module tests

import gleam/string

/// Assert that a string contains a substring
pub fn contain(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False ->
      panic as string.concat([
        "\nExpected string to contain: \n",
        needle,
        "\n\nBut got:\n",
        haystack,
      ])
  }
}

/// Assert that a string does NOT contain a substring
pub fn not_contain(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    False -> Nil
    True ->
      panic as string.concat([
        "\nExpected string to NOT contain: \n",
        needle,
        "\n\nBut got:\n",
        haystack,
      ])
  }
}
