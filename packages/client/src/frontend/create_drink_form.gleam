/// Create Drink Form Component
/// Modal form for creating a new drink under a store
/// Includes all states: idle, loading, error, success, empty

import frontend/model.{type DrinkFormState, type DrinkFormData, type Model, ImageUploadError, SubmitError, Submitting, Success, UploadingImage}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type TeaType, Black, tea_type_to_string, all_tea_types}

/// Render the create drink modal/form
pub fn view(model: Model) -> Element(Msg) {
  case model.show_create_form {
    False -> element.none()
    True -> {
      html.div([attribute.class("modal-overlay")], [
        html.div([attribute.class("modal create-drink-modal")], [
          render_header(),
          render_content(model),
          render_footer(model.form_state),
        ]),
      ])
    }
  }
}

/// Modal header with title and close button
fn render_header() -> Element(Msg) {
  html.div([attribute.class("modal-header")], [
    html.h2([], [element.text("Create New Drink")]),
    html.button(
      [
        attribute.class("close-button"),
        event.on_click(msg.CloseCreateDrinkForm),
        attribute.type_("button"),
      ],
      [element.text("×")],
    ),
  ])
}

/// Main form content with all fields
fn render_content(model: Model) -> Element(Msg) {
  html.div([attribute.class("modal-body")], [
    render_state_message(model.form_state),
    render_form(model.form_data, model.form_state),
  ])
}

/// Render state-specific messages (error, success, loading)
fn render_state_message(state: DrinkFormState) -> Element(Msg) {
  case state {
    ImageUploadError(error) -> {
      html.div([attribute.class("alert alert-error")], [
        element.text("Image upload failed: " <> error),
      ])
    }
    SubmitError(error) -> {
      html.div([attribute.class("alert alert-error")], [
        element.text("Failed to create drink: " <> error),
      ])
    }
    Success -> {
      html.div([attribute.class("alert alert-success")], [
        element.text("Drink created successfully!"),
      ])
    }
    _ -> element.none()
  }
}

/// Main form with all input fields
fn render_form(form_data: DrinkFormData, state: DrinkFormState) -> Element(Msg) {
  let is_disabled = case state {
    UploadingImage | Submitting -> True
    _ -> False
  }

  html.form(
    [
      attribute.class("create-drink-form"),
      event.on_submit(fn(_data) { msg.SubmitDrinkForm }),
    ],
    [
      // Name field (required)
      render_text_field(
        label: "Drink Name",
        id: "drink-name",
        value: form_data.name,
        required: True,
        placeholder: Some("e.g., Brown Sugar Boba Milk"),
        disabled: is_disabled,
        on_input: msg.UpdateDrinkName,
      ),

      // Tea type dropdown
      render_tea_type_dropdown(form_data.tea_type, is_disabled),

      // Price field
      render_number_field(
        label: "Price",
        id: "drink-price",
        value: form_data.price,
        required: False,
        placeholder: Some("0.00"),
        min: Some("0"),
        step: Some("0.01"),
        disabled: is_disabled,
        on_input: msg.UpdatePrice,
      ),

      // Description textarea
      render_textarea(
        label: "Description",
        id: "drink-description",
        value: form_data.description,
        required: False,
        placeholder: Some("Describe this drink..."),
        rows: 4,
        disabled: is_disabled,
        on_input: msg.UpdateDescription,
      ),

      // Image upload
      render_image_upload(form_data, is_disabled),

      // Is signature checkbox
      render_checkbox(
        label: "Signature Drink",
        id: "is-signature",
        checked: form_data.is_signature,
        disabled: is_disabled,
        on_change: msg.ToggleIsSignature,
      ),
    ],
  )
}

/// Text input field component
fn render_text_field(
  label label_text: String,
  id id_text: String,
  value value_text: String,
  required required_field: Bool,
  placeholder placeholder_text: Option(String),
  disabled is_disabled: Bool,
  on_input handler: fn(String) -> Msg,
) -> Element(Msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for(id_text)], [
      element.text(label_text),
      case required_field {
        True -> html.span([attribute.class("required")], [element.text(" *")])
        False -> element.none()
      },
    ]),
    html.input([
      attribute.type_("text"),
      attribute.id(id_text),
      attribute.name(id_text),
      attribute.value(value_text),
      attribute.required(required_field),
      attribute.disabled(is_disabled),
      case placeholder_text {
        Some(p) -> attribute.placeholder(p)
        None -> attribute.none()
      },
      event.on_input(handler),
    ]),
  ])
}

/// Number input field component
fn render_number_field(
  label label_text: String,
  id id_text: String,
  value value_text: String,
  required required_field: Bool,
  placeholder placeholder_text: Option(String),
  min min_value: Option(String),
  step step_value: Option(String),
  disabled is_disabled: Bool,
  on_input handler: fn(String) -> Msg,
) -> Element(Msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for(id_text)], [element.text(label_text)]),
    html.input(
      [
        attribute.type_("number"),
        attribute.id(id_text),
        attribute.name(id_text),
        attribute.value(value_text),
        attribute.required(required_field),
        attribute.disabled(is_disabled),
        case placeholder_text {
          Some(p) -> attribute.placeholder(p)
          None -> attribute.none()
        },
        case min_value {
          Some(m) -> attribute.min(m)
          None -> attribute.none()
        },
        case step_value {
          Some(s) -> attribute.attribute("step", s)
          None -> attribute.none()
        },
        event.on_input(handler),
      ],
    ),
  ])
}

/// Tea type dropdown component
fn render_tea_type_dropdown(
  selected: TeaType,
  disabled is_disabled: Bool,
) -> Element(Msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for("tea-type")], [element.text("Tea Type")]),
    html.select(
      [
        attribute.id("tea-type"),
        attribute.name("tea_type"),
        attribute.disabled(is_disabled),
        event.on_input(fn(value) {
          case shared.parse_tea_type(value) {
            Ok(tea_type) -> msg.UpdateTeaType(tea_type)
            Error(_) -> msg.UpdateTeaType(Black)
          }
        }),
      ],
      list.map(all_tea_types(), fn(tea_type) {
        html.option(
          [
            attribute.value(tea_type_to_string(tea_type)),
            attribute.selected(tea_type == selected),
          ],
          tea_type_to_string(tea_type),
        )
      }),
    ),
  ])
}

/// Textarea component
fn render_textarea(
  label label_text: String,
  id id_text: String,
  value value_text: String,
  required required_field: Bool,
  placeholder placeholder_text: Option(String),
  rows row_count: Int,
  disabled is_disabled: Bool,
  on_input handler: fn(String) -> Msg,
) -> Element(Msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for(id_text)], [element.text(label_text)]),
    html.textarea(
      [
        attribute.id(id_text),
        attribute.name(id_text),
        attribute.required(required_field),
        attribute.rows(row_count),
        attribute.disabled(is_disabled),
        case placeholder_text {
          Some(p) -> attribute.placeholder(p)
          None -> attribute.none()
        },
        event.on_input(handler),
      ],
      value_text,
    ),
  ])
}

/// Image upload component with preview
fn render_image_upload(form_data: DrinkFormData, disabled is_disabled: Bool) -> Element(Msg) {
  html.div([attribute.class("form-group image-upload")], [
    html.label([attribute.for("drink-image")], [element.text("Drink Image")]),

    // File input
    html.input([
      attribute.type_("file"),
      attribute.id("drink-image"),
      attribute.name("image"),
      attribute.accept(["image/*"]),
      attribute.disabled(is_disabled),
      event.on_input(msg.UpdateImageFile),
    ]),

    // Upload state indicator
    case form_data.image_file {
      "" -> element.none()
      _ -> html.div([attribute.class("upload-status")], [
        case is_disabled {
          True -> html.span([attribute.class("uploading")], [element.text("Uploading...")])
          False -> html.span([attribute.class("uploaded")], [element.text("Image selected")])
        },
      ])
    },

    // Image preview if URL available
    case form_data.image_url {
      "" -> element.none()
      url -> html.div([attribute.class("image-preview")], [
        html.img([attribute.src(url), attribute.alt("Drink preview")]),
      ])
    },
  ])
}

/// Checkbox component
fn render_checkbox(
  label label_text: String,
  id id_text: String,
  checked is_checked: Bool,
  disabled is_disabled: Bool,
  on_change handler: Msg,
) -> Element(Msg) {
  html.div([attribute.class("form-group checkbox-group")], [
    html.label([attribute.for(id_text), attribute.class("checkbox-label")], [
      html.input([
        attribute.type_("checkbox"),
        attribute.id(id_text),
        attribute.name(id_text),
        attribute.checked(is_checked),
        attribute.disabled(is_disabled),
        event.on_check(fn(_) { handler }),
      ]),
      element.text(label_text),
    ]),
  ])
}

/// Modal footer with action buttons
fn render_footer(state: DrinkFormState) -> Element(Msg) {
  let is_submitting = case state {
    UploadingImage | Submitting -> True
    _ -> False
  }

  let is_success = case state {
    Success -> True
    _ -> False
  }

  html.div([attribute.class("modal-footer")], [
    case is_success {
      True -> {
        // Success state: show "Create Another" and "Close" buttons
        html.div([attribute.class("button-group")], [
          html.button(
            [
              attribute.class("btn btn-secondary"),
              attribute.type_("button"),
              event.on_click(msg.ResetForm),
            ],
            [element.text("Create Another")],
          ),
          html.button(
            [
              attribute.class("btn btn-primary"),
              attribute.type_("button"),
              event.on_click(msg.CloseCreateDrinkForm),
            ],
            [element.text("Close")],
          ),
        ])
      }
      False -> {
        // Normal state: Cancel and Create buttons
        html.div([attribute.class("button-group")], [
          html.button(
            [
              attribute.class("btn btn-secondary"),
              attribute.type_("button"),
              event.on_click(msg.CloseCreateDrinkForm),
            ],
            [element.text("Cancel")],
          ),
          html.button(
            [
              attribute.class("btn btn-primary"),
              attribute.type_("submit"),
              attribute.disabled(is_submitting),
            ],
            [
              case is_submitting {
                True -> element.text("Creating...")
                False -> element.text("Create Drink")
              },
            ],
          ),
        ])
      }
    },
  ])
}

/// Helper: Render a standalone button to open the form from store detail page
pub fn render_create_button(store_id: String) -> Element(Msg) {
  html.button(
    [
      attribute.class("btn btn-primary create-drink-btn"),
      attribute.type_("button"),
      event.on_click(msg.OpenCreateDrinkForm(store_id)),
    ],
    [element.text("Add New Drink")],
  )
}
