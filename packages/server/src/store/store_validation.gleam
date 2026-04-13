import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Validation error for a specific field
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Validation result: either Valid or contains list of errors
pub type ValidationResult {
  Valid
  Invalid(List(ValidationError))
}

/// Input for store validation
pub type StoreValidationInput {
  StoreValidationInput(
    name: String,
    address: Option(String),
    phone: Option(String),
  )
}

/// Maximum length for store name
const max_name_length = 255

/// Minimum length for store name
const min_name_length = 2

/// Maximum length for address
const max_address_length = 500

/// Validate store input data
pub fn validate(input: StoreValidationInput) -> ValidationResult {
  let name_errors = validate_name(input.name)
  let address_errors = validate_address(input.address)
  let phone_errors = validate_phone(input.phone)

  let all_errors = list.flatten([name_errors, address_errors, phone_errors])

  case all_errors {
    [] -> Valid
    _ -> Invalid(all_errors)
  }
}

/// Validate name field: required, 2-255 characters
fn validate_name(name: String) -> List(ValidationError) {
  let trimmed = string.trim(name)
  let length = string.length(trimmed)

  case string.is_empty(trimmed), length < min_name_length, length > max_name_length {
    True, _, _ -> [ValidationError("name", "Name is required")]
    False, True, _ -> [ValidationError("name", "Name must be at least 2 characters")]
    False, False, True -> [ValidationError("name", "Name must not exceed 255 characters")]
    False, False, False -> []
  }
}

/// Validate address field: optional, max 500 characters if provided
fn validate_address(address: Option(String)) -> List(ValidationError) {
  case address {
    None -> []
    Some(value) -> {
      let trimmed = string.trim(value)
      let length = string.length(trimmed)

      case length > max_address_length {
        True -> [ValidationError("address", "Address must not exceed 500 characters")]
        False -> []
      }
    }
  }
}

/// Validate phone field: optional, must match phone format if provided
fn validate_phone(phone: Option(String)) -> List(ValidationError) {
  case phone {
    None -> []
    Some(value) -> {
      let trimmed = string.trim(value)

      case string.is_empty(trimmed) {
        True -> []
        False -> {
          case is_valid_phone(trimmed) {
            True -> []
            False -> [ValidationError("phone", "Phone must be a valid phone number")]
          }
        }
      }
    }
  }
}

/// Check if phone number matches valid formats without using regex:
/// - E.164: +1234567890
/// - US format: (123) 456-7890
/// - With dashes: 123-456-7890 or 555-9999
/// - With dots: 123.456.7890
/// - Plain: 1234567890
fn is_valid_phone(phone: String) -> Bool {
  let digits_only = extract_digits(phone)
  let digit_count = string.length(digits_only)

  // Check for valid digit counts: 7 (local), 10 (US), or 11 (with country code)
  let valid_digit_count = digit_count == 7 || digit_count == 10 || digit_count == 11

  // Check if it starts with + for E.164 format
  let starts_with_plus = string.starts_with(phone, "+")

  // If starts with +, it should be followed by 10-15 digits total (including country code)
  let valid_e164 = case starts_with_plus {
    True -> {
      // Remove leading + and extract digits
      let plus_digits = case string.pop_grapheme(phone) {
        Ok(#(_, rest)) -> extract_digits(rest)
        Error(Nil) -> ""
      }
      string.length(plus_digits) >= 10 && string.length(plus_digits) <= 15
    }
    False -> valid_digit_count
  }

  // Additional format validation for non-E.164 formats
  let valid_format = case starts_with_plus {
    True -> valid_e164
    False -> {
      // Check standard US format patterns
      is_us_format(phone) || is_dashed_format(phone) || is_dotted_format(phone) || is_plain_format(phone) || is_local_format(phone)
    }
  }

  valid_format && valid_digit_count
}

/// Check if phone is a local 7-digit format (no area code)
fn is_local_format(phone: String) -> Bool {
  let digits_only = extract_digits(phone)
  let digit_count = string.length(digits_only)

  // Local format is 7 digits with optional dash
  digit_count == 7 && string.contains(phone, "-")
}

/// Extract only digit characters from string
fn extract_digits(s: String) -> String {
  string.to_graphemes(s)
  |> list.filter(fn(c) { is_digit(c) })
  |> string.concat
}

/// Check if character is a digit
fn is_digit(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

/// Check if phone matches (123) 456-7890 or (123)456-7890 format
fn is_us_format(phone: String) -> Bool {
  // Pattern: (XXX) XXX-XXXX or (XXX)XXX-XXXX
  let has_area_parens = string.starts_with(phone, "(")
  let parts = string.split(phone, ")")

  case parts, has_area_parens {
    [area_part, rest], True -> {
      let area_digits = extract_digits(area_part)
      let rest_digits = extract_digits(rest)
      let area_valid = string.length(area_digits) == 3
      let rest_valid = string.length(rest_digits) == 7
      let has_separators = string.contains(rest, "-") || string.contains(rest, " ")
      area_valid && rest_valid && has_separators
    }
    _, _ -> False
  }
}

/// Check if phone matches XXX-XXX-XXXX or XXX-XXXX format
fn is_dashed_format(phone: String) -> Bool {
  let parts = string.split(phone, "-")
  case parts {
    // Standard 10-digit format: 123-456-7890
    [a, b, c] -> {
      let d1 = extract_digits(a)
      let d2 = extract_digits(b)
      let d3 = extract_digits(c)
      string.length(d1) == 3 && string.length(d2) == 3 && string.length(d3) == 4
    }
    // Local 7-digit format: 555-9999
    [a, b] -> {
      let d1 = extract_digits(a)
      let d2 = extract_digits(b)
      string.length(d1) == 3 && string.length(d2) == 4
    }
    _ -> False
  }
}

/// Check if phone matches XXX.XXX.XXXX format
fn is_dotted_format(phone: String) -> Bool {
  let parts = string.split(phone, ".")
  case parts {
    [a, b, c] -> {
      let d1 = extract_digits(a)
      let d2 = extract_digits(b)
      let d3 = extract_digits(c)
      string.length(d1) == 3 && string.length(d2) == 3 && string.length(d3) == 4
    }
    _ -> False
  }
}

/// Check if phone is exactly 10 digits with no separators
fn is_plain_format(phone: String) -> Bool {
  let digits = extract_digits(phone)
  string.length(digits) == 10 && string.length(phone) == 10
}

/// Convert validation errors to list of field-message pairs
pub fn errors_to_pairs(errors: List(ValidationError)) -> List(#(String, String)) {
  list.map(errors, fn(error) { #(error.field, error.message) })
}
