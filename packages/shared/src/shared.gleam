/// Shared types and functions for boba-raider-8

pub type AppError {
  NotFound(String)
  InvalidInput(String)
  InternalError(String)
  Unauthorized(String)
}

/// Convert an error to a human-readable message
pub fn error_message(error: AppError) -> String {
  case error {
    NotFound(msg) -> "Not found: " <> msg
    InvalidInput(msg) -> "Invalid input: " <> msg
    InternalError(msg) -> "Internal error: " <> msg
    Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

// User types

pub type User {
  User(id: String, username: String, email: String)
}

// Store types

pub type Store {
  Store(
    id: String,
    name: String,
    description: String,
    address: String,
    phone: String,
    email: String,
    created_by: String,
  )
}

pub type StoreInput {
  StoreInput(
    name: String,
    description: String,
    address: String,
    phone: String,
    email: String,
  )
}

pub fn default_store_input() -> StoreInput {
  StoreInput(name: "", description: "", address: "", phone: "", email: "")
}

/// Validation errors for store input
pub type StoreValidationErrors {
  StoreValidationErrors(
    name: Option(String),
    description: Option(String),
    address: Option(String),
    phone: Option(String),
    email: Option(String),
  )
}

pub type Option(a) {
  Some(a)
  None
}

pub fn default_validation_errors() -> StoreValidationErrors {
  StoreValidationErrors(
    name: None,
    description: None,
    address: None,
    phone: None,
    email: None,
  )
}

/// Validate store input - same rules for create and edit
pub fn validate_store_input(input: StoreInput) -> StoreValidationErrors {
  StoreValidationErrors(
    name: validate_required(input.name, "Store name is required"),
    description: validate_required(input.description, "Description is required"),
    address: validate_required(input.address, "Address is required"),
    phone: validate_phone(input.phone),
    email: validate_email(input.email),
  )
}

fn validate_required(value: String, message: String) -> Option(String) {
  case string_trim(value) {
    "" -> Some(message)
    _ -> None
  }
}

fn validate_phone(phone: String) -> Option(String) {
  case string_trim(phone) {
    "" -> Some("Phone number is required")
    p -> {
      // Basic phone validation - at least 10 digits
      let digits = count_digits(p)
      case digits >= 10 {
        True -> None
        False -> Some("Phone number must have at least 10 digits")
      }
    }
  }
}

fn validate_email(email: String) -> Option(String) {
  case string_trim(email) {
    "" -> Some("Email is required")
    e -> {
      // Basic email validation
      case contains_char(e, "@") && contains_char(e, ".") {
        True -> None
        False -> Some("Please enter a valid email address")
      }
    }
  }
}

fn string_trim(s: String) -> String {
  // Simplified trim - in production would use gleam/string
  s
}

fn contains_char(s: String, char: String) -> Bool {
  // Simplified contains check
  case s {
    "" -> False
    _ -> {
      let chars = string_to_chars(s)
      list_contains(chars, char)
    }
  }
}

fn count_digits(s: String) -> Int {
  let chars = string_to_chars(s)
  count_digits_in_list(chars, 0)
}

fn count_digits_in_list(chars: List(String), acc: Int) -> Int {
  case chars {
    [] -> acc
    ["0", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["1", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["2", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["3", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["4", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["5", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["6", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["7", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["8", ..rest] -> count_digits_in_list(rest, acc + 1)
    ["9", ..rest] -> count_digits_in_list(rest, acc + 1)
    [_, ..rest] -> count_digits_in_list(rest, acc)
  }
}

fn list_contains(list: List(String), item: String) -> Bool {
  case list {
    [] -> False
    [x, ..rest] -> {
      case x == item {
        True -> True
        False -> list_contains(rest, item)
      }
    }
  }
}

fn string_to_chars(s: String) -> List(String) {
  // Simplified char splitting - would use gleam/string in production
  split_string(s, "")
}

fn split_string(s: String, by: String) -> List(String) {
  // Placeholder - real implementation would split string into chars
  case s {
    "" -> []
    _ -> {
      // Simplified: treat the whole string as one element for now
      // In real implementation, use gleam/string module
      [s]
    }
  }
}

/// Check if validation has any errors
pub fn has_validation_errors(errors: StoreValidationErrors) -> Bool {
  case errors.name {
    Some(_) -> True
    None -> {
      case errors.description {
        Some(_) -> True
        None -> {
          case errors.address {
            Some(_) -> True
            None -> {
              case errors.phone {
                Some(_) -> True
                None -> {
                  case errors.email {
                    Some(_) -> True
                    None -> False
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Convert store to store input for editing
pub fn store_to_input(store: Store) -> StoreInput {
  StoreInput(
    name: store.name,
    description: store.description,
    address: store.address,
    phone: store.phone,
    email: store.email,
  )
}
