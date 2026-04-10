/// Message types for Create Store Page
/// Separated to avoid circular imports with API module

import gleam/option.{type Option, None}

// =============================================================================
// MESSAGE TYPE
// =============================================================================

/// All messages that can be sent from the Create Store page
pub type Msg {
  // Form field updates
  NameChanged(String)
  AddressChanged(String)
  PhoneChanged(String)
  HoursChanged(String)
  DescriptionChanged(String)

  // Field blur (for validation)
  NameBlurred
  AddressBlurred
  PhoneBlurred
  HoursBlurred
  DescriptionBlurred

  // Image upload
  ImageSelected(String)           // File selected
  ImagePreviewGenerated(String)   // Data URL for preview
  ImageUploadProgress(Int)        // Upload progress (0-100)
  ImageUploaded(String)           // Upload complete - server URL
  ImageUploadFailed(String)       // Upload error
  ImageCleared                    // Remove selected image

  // Geocoding
  GeocodeRequested                // Trigger geocode lookup
  GeocodeSuccess(GeocodeResult)   // Geocode result received
  GeocodeFailed(String)           // Geocode error

  // Form submission
  SubmitForm(List(#(String, String)))  // Form submission with data
  SubmitSuccess(String)           // Store created - returns store ID
  SubmitFailed(String)            // API error

  // Navigation
  CancelClicked                   // User cancelled
}

/// Geocode result from address lookup
pub type GeocodeResult {
  GeocodeResult(
    latitude: Float,
    longitude: Float,
    formatted_address: String
  )
}

/// Field-level validation error
pub type ValidationError {
  Required
  InvalidFormat(String)
  TooShort(Int, Int)  // (min, actual)
  TooLong(Int, Int)   // (max, actual)
}

/// A form field with its value and validation state
pub type FormField {
  FormField(
    value: String,
    touched: Bool,
    error: Option(ValidationError)
  )
}

/// Image upload state
pub type ImageUpload {
  ImageUpload(
    file: Option(String),        // File name/path
    preview_url: Option(String),   // Data URL for preview
    uploaded_url: Option(String), // URL after upload
    uploading: Bool,
    error: Option(String)
  )
}

/// Form state
pub type StoreForm {
  StoreForm(
    name: FormField,
    address: FormField,
    phone: FormField,
    hours: FormField,
    description: FormField,
    image: ImageUpload,
    geocode_result: Option(GeocodeResult),
    geocoding: Bool
  )
}

/// Page-level state
pub type CreateStoreState {
  Idle(StoreForm)
  Submitting(StoreForm)
  Success(String)  // Store ID for redirect
  Error(StoreForm, String)
}

// =============================================================================
// ERROR MESSAGES
// =============================================================================

/// Convert validation error to display message
pub fn error_to_string(error: ValidationError) -> String {
  case error {
    Required -> "This field is required"
    InvalidFormat(msg) -> msg
    TooShort(min, _actual) -> "Must be at least " <> int_to_string(min) <> " characters"
    TooLong(max, _actual) -> "Must be at most " <> int_to_string(max) <> " characters"
  }
}

/// Helper to convert int to string
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "10+"
  }
}

// =============================================================================
// INITIALIZATION
// =============================================================================

/// Initialize empty form
pub fn init_form() -> StoreForm {
  StoreForm(
    name: FormField(value: "", touched: False, error: None),
    address: FormField(value: "", touched: False, error: None),
    phone: FormField(value: "", touched: False, error: None),
    hours: FormField(value: "", touched: False, error: None),
    description: FormField(value: "", touched: False, error: None),
    image: ImageUpload(
      file: None,
      preview_url: None,
      uploaded_url: None,
      uploading: False,
      error: None
    ),
    geocode_result: None,
    geocoding: False
  )
}

/// Initialize page state
pub fn init() -> CreateStoreState {
  Idle(init_form())
}
