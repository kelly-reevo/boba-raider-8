import gleam/option.{type Option, None, Some}
import frontend/msg.{type Msg, CreateStoreSuccess, CreateStoreError}
import lustre/effect.{type Effect}

/// Submit create store form to API
pub fn submit_create_store(
  name: String,
  address: String,
  city: String,
  phone: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Build payload - omit empty optional fields or send as null
    let payload = build_payload(name, address, city, phone)

    // Call JavaScript FFI to make API request
    do_api_post(
      "/api/stores",
      payload,
      fn(result) {
        case result {
          Ok(json) -> {
            case extract_store_id(json) {
              Ok(store_id) -> dispatch(CreateStoreSuccess(store_id, name))
              Error(err) -> dispatch(CreateStoreError(err))
            }
          }
          Error(err) -> dispatch(CreateStoreError(err))
        }
      },
    )
  })
}

/// Build request payload from form fields
fn build_payload(
  name: String,
  address: String,
  city: String,
  phone: String,
) -> String {
  // Use gleam_json to build proper JSON
  let fields = ["\"name\": \"" <> json_escape(name) <> "\""]

  // Add optional fields if they have values
  let fields = case address {
    "" -> ["\"address\": null", ..fields]
    _ -> ["\"address\": \"" <> json_escape(address) <> "\"", ..fields]
  }

  let fields = case city {
    "" -> ["\"city\": null", ..fields]
    _ -> ["\"city\": \"" <> json_escape(city) <> "\"", ..fields]
  }

  let fields = case phone {
    "" -> ["\"phone\": null", ..fields]
    _ -> ["\"phone\": \"" <> json_escape(phone) <> "\"", ..fields]
  }

  "{" <> join_fields(fields, ", ") <> "}"
}

/// Join fields with separator
fn join_fields(fields: List(String), sep: String) -> String {
  case fields {
    [] -> ""
    [first, ..rest] -> do_join(rest, first, sep)
  }
}

fn do_join(fields: List(String), acc: String, sep: String) -> String {
  case fields {
    [] -> acc
    [next, ..rest] -> do_join(rest, acc <> sep <> next, sep)
  }
}

/// Escape special characters in JSON string
fn json_escape(s: String) -> String {
  s
  |> replace_all("\\", "\\\\")
  |> replace_all("\"", "\\\"")
  |> replace_all("\n", "\\n")
  |> replace_all("\r", "\\r")
  |> replace_all("\t", "\\t")
}

/// Replace all occurrences in string
fn replace_all(s: String, pattern: String, replacement: String) -> String {
  // Using JavaScript FFI for string replacement
  js_replace_all(s, pattern, replacement)
}

@external(javascript, "./validation_ffi.mjs", "replace_all")
fn js_replace_all(s: String, pattern: String, replacement: String) -> String

/// Make API POST request via JavaScript FFI
type ApiResult = Result(String, String)

@external(javascript, "./effects_ffi.mjs", "api_post")
fn do_api_post(
  url: String,
  payload: String,
  callback: fn(ApiResult) -> Nil,
) -> Nil

/// Extract store ID from API response JSON
fn extract_store_id(json: String) -> Result(String, String) {
  // Simple JSON parsing to extract id field
  // Looking for: "id": "some-value"
  case find_value(json, "\"id\"") {
    Some(id) -> Ok(id)
    None -> Error("Failed to extract store ID from response")
  }
}

/// Find a string value for a key in JSON
fn find_value(json: String, key: String) -> Option(String) {
  case string_contains(json, key) {
    False -> None
    True -> {
      let key_pos = string_index_of(json, key)
      case key_pos {
        -1 -> None
        pos -> {
          let after_key = string_slice_from(json, pos + string_length(key))
          // Skip colon and whitespace
          let after_colon = skip_to_value(after_key)
          extract_string_value(after_colon)
        }
      }
    }
  }
}

/// Skip whitespace and colon to get to value
fn skip_to_value(s: String) -> String {
  s
  |> string_trim_left()
  |> skip_colon()
  |> string_trim_left()
}

fn skip_colon(s: String) -> String {
  case string_starts_with(s, ":") {
    True -> string_slice_from(s, 1)
    False -> s
  }
}

/// Extract quoted string value
fn extract_string_value(s: String) -> Option(String) {
  case string_starts_with(s, "\"") {
    False -> None
    True -> {
      let rest = string_slice_from(s, 1)
      case find_closing_quote(rest, 0) {
        -1 -> None
        end -> Some(string_slice(rest, 0, end))
      }
    }
  }
}

/// Find position of unescaped closing quote
fn find_closing_quote(s: String, pos: Int) -> Int {
  case pos >= string_length(s) {
    True -> -1
    False -> {
      let char = string_slice(s, pos, 1)
      case char {
        "\"" -> {
          // Check if escaped
          case pos > 0 && string_slice(s, pos - 1, 1) == "\\" {
            True -> find_closing_quote(s, pos + 1)
            False -> pos
          }
        }
        _ -> find_closing_quote(s, pos + 1)
      }
    }
  }
}

// FFI imports for string operations
@external(javascript, "./effects_ffi.mjs", "string_contains")
fn string_contains(s: String, pattern: String) -> Bool

@external(javascript, "./effects_ffi.mjs", "string_index_of")
fn string_index_of(s: String, pattern: String) -> Int

@external(javascript, "./effects_ffi.mjs", "string_slice")
fn string_slice(s: String, start: Int, end: Int) -> String

@external(javascript, "./effects_ffi.mjs", "string_slice_from")
fn string_slice_from(s: String, start: Int) -> String

@external(javascript, "./effects_ffi.mjs", "string_length")
fn string_length(s: String) -> Int

@external(javascript, "./effects_ffi.mjs", "string_trim_left")
fn string_trim_left(s: String) -> String

@external(javascript, "./effects_ffi.mjs", "string_starts_with")
fn string_starts_with(s: String, prefix: String) -> Bool
