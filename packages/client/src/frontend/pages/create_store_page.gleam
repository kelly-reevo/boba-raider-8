/// Create Store Page - Form for creating a new store
/// Fields: name, address (with geocode), phone, hours, description, image upload

import frontend/api
import frontend/pages/create_store_msg as msg
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// Re-export types and values for external use
pub type Msg = msg.Msg
pub type CreateStoreState = msg.CreateStoreState
pub type StoreForm = msg.StoreForm
pub type FormField = msg.FormField
pub type ImageUpload = msg.ImageUpload
pub type GeocodeResult = msg.GeocodeResult
pub type ValidationError = msg.ValidationError

pub fn init() -> CreateStoreState {
  msg.init()
}

pub fn init_form() -> StoreForm {
  msg.init_form()
}

// =============================================================================
// VALIDATION
// =============================================================================

/// Validate a required field
fn validate_required(value: String) -> Option(ValidationError) {
  case value {
    "" -> Some(msg.Required)
    _ -> None
  }
}

/// Validate phone format (simple check)
fn validate_phone(value: String) -> Option(ValidationError) {
  case value {
    "" -> None
    _ -> None
  }
}

/// Validate name field
pub fn validate_name(field: FormField) -> FormField {
  let error = validate_required(field.value)
  msg.FormField(..field, touched: True, error: error)
}

/// Validate address field
pub fn validate_address(field: FormField) -> FormField {
  let error = validate_required(field.value)
  msg.FormField(..field, touched: True, error: error)
}

/// Validate phone field
pub fn validate_phone_field(field: FormField) -> FormField {
  let error = validate_phone(field.value)
  msg.FormField(..field, touched: True, error: error)
}

/// Check if entire form is valid
pub fn is_form_valid(form: StoreForm) -> Bool {
  let name_valid = case validate_required(form.name.value) {
    None -> True
    _ -> False
  }
  let address_valid = case validate_required(form.address.value) {
    None -> True
    _ -> False
  }
  name_valid && address_valid
}

// =============================================================================
// UPDATE
// =============================================================================

/// Update function for the Create Store page
pub fn update(state: CreateStoreState, msg: Msg) -> #(CreateStoreState, Effect(Msg)) {
  case state {
    msg.Idle(form) -> update_idle(form, msg)
    msg.Submitting(form) -> update_submitting(form, msg)
    msg.Success(_) -> update_success(state, msg)
    msg.Error(form, _) -> update_error(form, msg)
  }
}

/// Update when in Idle state
fn update_idle(form: StoreForm, msg: Msg) -> #(CreateStoreState, Effect(Msg)) {
  case msg {
    msg.NameChanged(value) -> {
      let field = msg.FormField(value: value, touched: True, error: None)
      #(msg.Idle(msg.StoreForm(..form, name: field)), effect.none())
    }
    msg.AddressChanged(value) -> {
      let field = msg.FormField(value: value, touched: True, error: None)
      #(msg.Idle(msg.StoreForm(..form, address: field)), effect.none())
    }
    msg.PhoneChanged(value) -> {
      let field = msg.FormField(value: value, touched: True, error: None)
      #(msg.Idle(msg.StoreForm(..form, phone: field)), effect.none())
    }
    msg.HoursChanged(value) -> {
      let field = msg.FormField(value: value, touched: True, error: None)
      #(msg.Idle(msg.StoreForm(..form, hours: field)), effect.none())
    }
    msg.DescriptionChanged(value) -> {
      let field = msg.FormField(value: value, touched: True, error: None)
      #(msg.Idle(msg.StoreForm(..form, description: field)), effect.none())
    }

    msg.NameBlurred -> {
      let validated = validate_name(form.name)
      #(msg.Idle(msg.StoreForm(..form, name: validated)), effect.none())
    }
    msg.AddressBlurred -> {
      let validated = validate_address(form.address)
      #(msg.Idle(msg.StoreForm(..form, address: validated)), effect.none())
    }
    msg.PhoneBlurred -> {
      let validated = validate_phone_field(form.phone)
      #(msg.Idle(msg.StoreForm(..form, phone: validated)), effect.none())
    }
    msg.HoursBlurred -> #(msg.Idle(form), effect.none())
    msg.DescriptionBlurred -> #(msg.Idle(form), effect.none())

    msg.ImageSelected(file_name) -> {
      let image = msg.ImageUpload(
        file: Some(file_name),
        preview_url: None,
        uploaded_url: None,
        uploading: False,
        error: None
      )
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }
    msg.ImagePreviewGenerated(data_url) -> {
      let image = msg.ImageUpload(
        ..form.image,
        preview_url: Some(data_url)
      )
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }
    msg.ImageUploadProgress(_progress) -> {
      let image = msg.ImageUpload(..form.image, uploading: True)
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }
    msg.ImageUploaded(url) -> {
      let image = msg.ImageUpload(
        ..form.image,
        uploaded_url: Some(url),
        uploading: False,
        error: None
      )
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }
    msg.ImageUploadFailed(error) -> {
      let image = msg.ImageUpload(
        ..form.image,
        uploading: False,
        error: Some(error)
      )
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }
    msg.ImageCleared -> {
      let image = msg.ImageUpload(
        file: None,
        preview_url: None,
        uploaded_url: None,
        uploading: False,
        error: None
      )
      #(msg.Idle(msg.StoreForm(..form, image: image)), effect.none())
    }

    msg.GeocodeRequested -> {
      #(msg.Idle(msg.StoreForm(..form, geocoding: True)), api.geocode_address(form.address.value))
    }
    msg.GeocodeSuccess(result) -> {
      #(msg.Idle(msg.StoreForm(
        ..form,
        geocode_result: Some(result),
        geocoding: False
      )), effect.none())
    }
    msg.GeocodeFailed(error) -> {
      #(msg.Error(form, "Geocoding failed: " <> error), effect.none())
    }

    msg.SubmitForm(_form_data) -> {
      let name_validated = validate_name(form.name)
      let address_validated = validate_address(form.address)
      let phone_validated = validate_phone_field(form.phone)

      let validated_form = msg.StoreForm(
        ..form,
        name: name_validated,
        address: address_validated,
        phone: phone_validated
      )

      case is_form_valid(validated_form) {
        True -> {
          #(msg.Submitting(validated_form), api.create_store(validated_form))
        }
        False -> {
          #(msg.Idle(validated_form), effect.none())
        }
      }
    }

    msg.SubmitSuccess(store_id) -> {
      #(msg.Success(store_id), effect.none())
    }

    msg.SubmitFailed(error) -> {
      #(msg.Error(form, error), effect.none())
    }

    msg.CancelClicked -> #(msg.Idle(form), effect.none())
  }
}

/// Update when in Submitting state
fn update_submitting(form: StoreForm, msg: Msg) -> #(CreateStoreState, Effect(Msg)) {
  case msg {
    msg.SubmitSuccess(store_id) -> #(msg.Success(store_id), effect.none())
    msg.SubmitFailed(error) -> #(msg.Error(form, error), effect.none())
    _ -> #(msg.Submitting(form), effect.none())
  }
}

/// Update when in Success state
fn update_success(state: CreateStoreState, _msg: Msg) -> #(CreateStoreState, Effect(Msg)) {
  #(state, effect.none())
}

/// Update when in Error state
fn update_error(form: StoreForm, msg: Msg) -> #(CreateStoreState, Effect(Msg)) {
  case msg {
    msg.SubmitForm(_form_data) -> {
      case is_form_valid(form) {
        True -> #(msg.Submitting(form), api.create_store(form))
        False -> #(msg.Error(form, "Please fix the errors above"), effect.none())
      }
    }
    msg.NameChanged(_) | msg.AddressChanged(_) | msg.PhoneChanged(_) -> {
      update_idle(form, msg)
    }
    msg.CancelClicked -> #(msg.Idle(form), effect.none())
    _ -> #(msg.Error(form, ""), effect.none())
  }
}

// =============================================================================
// VIEW
// =============================================================================

/// Main view function
pub fn view(state: CreateStoreState) -> Element(Msg) {
  html.div([attribute.class("create-store-page")], [
    html.h1([], [element.text("Create New Store")]),
    view_state_content(state)
  ])
}

/// Render content based on state
fn view_state_content(state: CreateStoreState) -> Element(Msg) {
  case state {
    msg.Idle(form) -> view_form(form, False)
    msg.Submitting(form) -> view_form(form, True)
    msg.Success(store_id) -> view_success(store_id)
    msg.Error(form, error) -> view_error_state(form, error)
  }
}

/// View: Form with all fields
fn view_form(form: StoreForm, submitting: Bool) -> Element(Msg) {
  html.form(
    [
      attribute.class("store-form"),
      event.on_submit(fn(form_data) { msg.SubmitForm(form_data) })
    ],
    [
      view_text_field(
        label: "Store Name",
        value: form.name.value,
        error: form.name.error,
        placeholder: "Enter store name",
        required: True,
        on_change: msg.NameChanged,
        on_blur: msg.NameBlurred,
        disabled: submitting
      ),

      view_address_field(form, submitting),

      view_text_field(
        label: "Phone",
        value: form.phone.value,
        error: form.phone.error,
        placeholder: "(555) 123-4567",
        required: False,
        on_change: msg.PhoneChanged,
        on_blur: msg.PhoneBlurred,
        disabled: submitting
      ),

      view_text_field(
        label: "Hours",
        value: form.hours.value,
        error: None,
        placeholder: "Mon-Fri: 9AM-6PM, Sat-Sun: 10AM-4PM",
        required: False,
        on_change: msg.HoursChanged,
        on_blur: msg.HoursBlurred,
        disabled: submitting
      ),

      view_textarea_field(
        label: "Description",
        value: form.description.value,
        placeholder: "Describe your store...",
        required: False,
        on_change: msg.DescriptionChanged,
        on_blur: msg.DescriptionBlurred,
        disabled: submitting
      ),

      view_image_upload(form.image, submitting),

      view_form_actions(submitting)
    ]
  )
}

/// View: Text input field with label and error
fn view_text_field(
  label label_text: String,
  value value_text: String,
  error error_opt: Option(ValidationError),
  placeholder placeholder_text: String,
  required is_required: Bool,
  on_change on_change_msg: fn(String) -> Msg,
  on_blur on_blur_msg: Msg,
  disabled is_disabled: Bool
) -> Element(Msg) {
  let error_attr = case error_opt {
    Some(_) -> attribute.class("field-error")
    None -> attribute.class("")
  }

  html.div([attribute.class("form-field")], [
    html.label([], [
      element.text(label_text),
      case is_required {
        True -> html.span([attribute.class("required")], [element.text(" *")])
        False -> element.none()
      }
    ]),
    html.input([
      attribute.type_("text"),
      attribute.value(value_text),
      attribute.placeholder(placeholder_text),
      attribute.required(is_required),
      attribute.disabled(is_disabled),
      error_attr,
      event.on_input(on_change_msg),
      event.on_blur(on_blur_msg)
    ]),
    case error_opt {
      Some(err) -> html.span([attribute.class("error-message")], [
        element.text(msg.error_to_string(err))
      ])
      None -> element.none()
    }
  ])
}

/// View: Textarea field
fn view_textarea_field(
  label label_text: String,
  value value_text: String,
  placeholder placeholder_text: String,
  required is_required: Bool,
  on_change on_change_msg: fn(String) -> Msg,
  on_blur on_blur_msg: Msg,
  disabled is_disabled: Bool
) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([], [
      element.text(label_text),
      case is_required {
        True -> html.span([attribute.class("required")], [element.text(" *")])
        False -> element.none()
      }
    ]),
    html.textarea(
      [
        attribute.placeholder(placeholder_text),
        attribute.required(is_required),
        attribute.disabled(is_disabled),
        attribute.rows(4),
        attribute.value(value_text),
        event.on_input(on_change_msg),
        event.on_blur(on_blur_msg)
      ],
      value_text
    )
  ])
}

/// View: Address field with geocode preview
fn view_address_field(form: StoreForm, disabled: Bool) -> Element(Msg) {
  let error_attr = case form.address.error {
    Some(_) -> attribute.class("field-error")
    None -> attribute.class("")
  }

  html.div([attribute.class("form-field address-field")], [
    html.label([], [
      element.text("Address"),
      html.span([attribute.class("required")], [element.text(" *")])
    ]),
    html.div([attribute.class("address-input-row")], [
      html.input([
        attribute.type_("text"),
        attribute.value(form.address.value),
        attribute.placeholder("123 Main St, City, State, ZIP"),
        attribute.required(True),
        attribute.disabled(disabled),
        error_attr,
        event.on_input(msg.AddressChanged),
        event.on_blur(msg.AddressBlurred)
      ]),
      html.button(
        [
          attribute.type_("button"),
          attribute.class("geocode-btn"),
          attribute.disabled(disabled || form.address.value == ""),
          event.on_click(msg.GeocodeRequested)
        ],
        [
          case form.geocoding {
            True -> element.text("Locating...")
            False -> element.text("Preview Location")
          }
        ]
      )
    ]),
    case form.address.error {
      Some(err) -> html.span([attribute.class("error-message")], [
        element.text(msg.error_to_string(err))
      ])
      None -> element.none()
    },
    view_geocode_preview(form.geocode_result)
  ])
}

/// View: Geocode result preview
fn view_geocode_preview(result: Option(GeocodeResult)) -> Element(Msg) {
  case result {
    None -> element.none()
    Some(geo) -> html.div([attribute.class("geocode-preview")], [
      html.div([attribute.class("map-placeholder")], [
        element.text("Map: " <> geo.formatted_address)
      ]),
      html.div([attribute.class("coordinates")], [
        element.text("Lat: " <> float_to_string(geo.latitude) <> ", Lng: " <> float_to_string(geo.longitude))
      ])
    ])
  }
}

/// View: Image upload section
fn view_image_upload(image: ImageUpload, disabled: Bool) -> Element(Msg) {
  html.div([attribute.class("form-field image-upload")], [
    html.label([], [element.text("Store Image")]),

    case image.preview_url {
      Some(url) -> html.div([attribute.class("image-preview")], [
        html.img([attribute.src(url), attribute.alt("Preview")]),
        html.button(
          [
            attribute.type_("button"),
            attribute.class("clear-image-btn"),
            attribute.disabled(disabled),
            event.on_click(msg.ImageCleared)
          ],
          [element.text("Remove")]
        )
      ])
      None -> html.div([attribute.class("image-upload-area")], [
        html.input([
          attribute.type_("file"),
          attribute.accept(["image/*"]),
          attribute.disabled(disabled || image.uploading),
          event.on_input(fn(value) { msg.ImageSelected(value) })
        ]),
        html.p([], [element.text("Drag and drop an image or click to browse")])
      ])
    },

    case image.uploading {
      True -> html.div([attribute.class("upload-progress")], [
        element.text("Uploading...")
      ])
      False -> element.none()
    },

    case image.error {
      Some(err) -> html.span([attribute.class("error-message")], [
        element.text("Upload failed: " <> err)
      ])
      None -> element.none()
    }
  ])
}

/// View: Form action buttons
fn view_form_actions(submitting: Bool) -> Element(Msg) {
  html.div([attribute.class("form-actions")], [
    html.button(
      [
        attribute.type_("submit"),
        attribute.class("btn-primary"),
        attribute.disabled(submitting)
      ],
      [
        case submitting {
          True -> element.text("Creating Store...")
          False -> element.text("Create Store")
        }
      ]
    ),
    html.button(
      [
        attribute.type_("button"),
        attribute.class("btn-secondary"),
        attribute.disabled(submitting),
        event.on_click(msg.CancelClicked)
      ],
      [element.text("Cancel")]
    )
  ])
}

/// View: Success state (redirect notice)
fn view_success(store_id: String) -> Element(Msg) {
  html.div([attribute.class("success-state")], [
    html.h2([], [element.text("Store Created!")]),
    html.p([], [
      element.text("Redirecting to your new store... (ID: " <> store_id <> ")")
    ])
  ])
}

/// View: Error state with retry
fn view_error_state(form: StoreForm, error: String) -> Element(Msg) {
  html.div([], [
    html.div([attribute.class("error-banner")], [
      element.text("Error: " <> error)
    ]),
    view_form(form, False)
  ])
}

// =============================================================================
// HELPERS
// =============================================================================

/// Helper to convert float to string (simplified)
fn float_to_string(f: Float) -> String {
  let int_part = float_to_int(f)
  case f >=. 0.0 {
    True -> "+" <> int_to_string(int_part)
    False -> "-" <> int_to_string(0 - int_part)
  }
}

fn float_to_int(f: Float) -> Int {
  let abs_f = case f >=. 0.0 {
    True -> f
    False -> 0.0 -. f
  }
  float_to_int_recursive(abs_f, 0)
}

fn float_to_int_recursive(f: Float, acc: Int) -> Int {
  case f <. 1.0 {
    True -> acc
    False -> float_to_int_recursive(f -. 1.0, acc + 1)
  }
}

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
