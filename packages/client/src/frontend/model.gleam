/// Application state for boba-raider-8 client

import gleam/option.{type Option, None, Some}
import gleam/string

/// Validation error for a form field
pub type FieldError {
  NameRequired
  NameTooShort
  NameTooLong
  InvalidPhoneFormat
}

/// Form field validation errors state
pub type FormErrors {
  FormErrors(
    name: Option(FieldError),
    phone: Option(FieldError),
  )
}

/// Form field values
pub type FormFields {
  FormFields(
    name: String,
    address: String,
    city: String,
    phone: String,
  )
}

/// Create store form state
pub type CreateStoreForm {
  CreateStoreForm(
    fields: FormFields,
    errors: FormErrors,
    is_submitting: Bool,
    submission_error: Option(String),
  )
}

/// Page state for routing
pub type Page {
  HomePage
  CreateStorePage
  StoreDetailPage(store_id: String)
}

/// Main application model
pub type Model {
  Model(
    count: Int,
    error: String,
    page: Page,
    create_store_form: CreateStoreForm,
  )
}

/// Default empty form errors
fn default_form_errors() -> FormErrors {
  FormErrors(name: None, phone: None)
}

/// Default empty form fields
fn default_form_fields() -> FormFields {
  FormFields(name: "", address: "", city: "", phone: "")
}

/// Default create store form state
fn default_create_store_form() -> CreateStoreForm {
  CreateStoreForm(
    fields: default_form_fields(),
    errors: default_form_errors(),
    is_submitting: False,
    submission_error: None,
  )
}

/// Default model state
pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    page: CreateStorePage,
    create_store_form: default_create_store_form(),
  )
}

/// Create a new form with cleared errors for a specific field
pub fn clear_field_error(form: CreateStoreForm, field: String) -> CreateStoreForm {
  let new_errors = case field {
    "name" -> FormErrors(..form.errors, name: None)
    "phone" -> FormErrors(..form.errors, phone: None)
    _ -> form.errors
  }
  CreateStoreForm(..form, errors: new_errors)
}

/// Update a form field value
pub fn update_field(
  form: CreateStoreForm,
  field: String,
  value: String,
) -> CreateStoreForm {
  let new_fields = case field {
    "name" -> FormFields(..form.fields, name: value)
    "address" -> FormFields(..form.fields, address: value)
    "city" -> FormFields(..form.fields, city: value)
    "phone" -> FormFields(..form.fields, phone: value)
    _ -> form.fields
  }
  // Clear error for the field being updated and submission error
  let form_with_cleared = clear_field_error(
    CreateStoreForm(..form, fields: new_fields),
    field,
  )
  CreateStoreForm(..form_with_cleared, submission_error: None)
}

/// Validate name field (2-255 chars, required)
fn validate_name(name: String) -> Option(FieldError) {
  let trimmed = name |> trim
  case string.length(trimmed) {
    0 -> Some(NameRequired)
    1 -> Some(NameTooShort)
    n if n > 255 -> Some(NameTooLong)
    _ -> None
  }
}

/// Validate phone format (optional field)
fn validate_phone(phone: String) -> Option(FieldError) {
  let trimmed = phone |> trim
  case string.length(trimmed) {
    0 -> None
    _ -> {
      // US phone regex: supports formats like 415-555-0123, (415) 555-0123, +1 415-555-0123, etc.
      let phone_regex = "^\\\\+?1?[-.\\s]?\\\\(?[0-9]{3}\\\\)?[-.\\s]?[0-9]{3}[-.\\s]?[0-9]{4}$"
      case regex_check(phone_regex, trimmed) {
        True -> None
        False -> Some(InvalidPhoneFormat)
      }
    }
  }
}

/// Trim whitespace from string
fn trim(s: String) -> String {
  s |> string.trim
}

/// Check if string matches regex pattern
fn regex_check(pattern: String, input: String) -> Bool {
  // Gleam doesn't have built-in regex in stdlib
  // Using JavaScript FFI for regex check
  js_regex_check(pattern, input)
}

/// JavaScript FFI for regex validation
@external(javascript, "./validation_ffi.mjs", "regex_check")
fn js_regex_check(pattern: String, input: String) -> Bool

/// Validate all form fields
pub fn validate_form(form: CreateStoreForm) -> FormErrors {
  FormErrors(
    name: validate_name(form.fields.name),
    phone: validate_phone(form.fields.phone),
  )
}

/// Check if form has any errors
pub fn has_errors(errors: FormErrors) -> Bool {
  option.is_some(errors.name) || option.is_some(errors.phone)
}

/// Get human-readable error message
pub fn error_to_string(error: FieldError) -> String {
  case error {
    NameRequired -> "Name is required"
    NameTooShort -> "Name is required (minimum 2 characters)"
    NameTooLong -> "Name is required (maximum 255 characters)"
    InvalidPhoneFormat -> "Invalid phone format"
  }
}
