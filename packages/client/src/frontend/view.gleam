import gleam/int
import gleam/option.{type Option, None, Some, is_some}
import frontend/model.{
  type Model, type CreateStoreForm, type Page, type FieldError,
  CreateStorePage, StoreDetailPage,
  error_to_string,
}
import frontend/msg.{type Msg, type Field,
  UpdateField, SubmitForm, NavigateTo,
  NameField, AddressField, CityField, PhoneField,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function - routes to appropriate page view
pub fn view(model: Model) -> Element(Msg) {
  case model.page {
    CreateStorePage -> create_store_view(model.create_store_form)
    StoreDetailPage(store_id) -> store_detail_view(store_id, model.create_store_form.fields.name)
    _ -> create_store_view(model.create_store_form)
  }
}

/// Create Store Form view
fn create_store_view(form: CreateStoreForm) -> Element(Msg) {
  html.div([attribute.class("create-store-container")], [
    html.h1([], [element.text("Create New Boba Store")]),

    // Submission error banner (if any)
    submission_error_view(form.submission_error),

    // Form
    html.form(
      [
        attribute.class("create-store-form"),
        event.on_submit(fn(_form_data) { SubmitForm }),
        attribute.attribute("data-testid", "create-store-form"),
      ],
      [
        // Name field (required)
        form_field_view(
          label: "Store Name",
          field_id: "store-name",
          input_type: "text",
          placeholder: "Enter store name",
          value: form.fields.name,
          field: NameField,
          error: form.errors.name,
          required: True,
          disabled: form.is_submitting,
        ),

        // Address field (optional)
        form_field_view(
          label: "Address",
          field_id: "store-address",
          input_type: "text",
          placeholder: "Enter store address",
          value: form.fields.address,
          field: AddressField,
          error: None,
          required: False,
          disabled: form.is_submitting,
        ),

        // City field (optional)
        form_field_view(
          label: "City",
          field_id: "store-city",
          input_type: "text",
          placeholder: "Enter city",
          value: form.fields.city,
          field: CityField,
          error: None,
          required: False,
          disabled: form.is_submitting,
        ),

        // Phone field (optional with validation)
        form_field_view(
          label: "Phone",
          field_id: "store-phone",
          input_type: "tel",
          placeholder: "e.g., 415-555-0123",
          value: form.fields.phone,
          field: PhoneField,
          error: form.errors.phone,
          required: False,
          disabled: form.is_submitting,
        ),

        // Submit button
        submit_button_view(form.is_submitting),
      ],
    ),
  ])
}

/// Single form field with label, input, and error message
fn form_field_view(
  label label_text: String,
  field_id id: String,
  input_type input_type: String,
  placeholder placeholder: String,
  value value: String,
  field field: Field,
  error error: Option(FieldError),
  required required: Bool,
  disabled disabled: Bool,
) -> Element(Msg) {
  let has_error = is_some(error)
  let error_id = id <> "-error"

  html.div(
    [
      attribute.class("form-field"),
      attribute.class(case has_error {
        True -> "form-field--error"
        False -> ""
      }),
    ],
    [
      // Label
      html.label(
        [
          attribute.for(id),
          attribute.class("form-label"),
        ],
        [
          element.text(label_text <> case required {
            True -> " *"
            False -> ""
          }),
        ],
      ),

      // Input
      html.input(
        [
          attribute.type_(input_type),
          attribute.id(id),
          attribute.attribute("data-testid", id <> "-input"),
          attribute.placeholder(placeholder),
          attribute.value(value),
          event.on_input(fn(val) { UpdateField(field, val) }),
          attribute.disabled(disabled),
          case has_error {
            True -> attribute.attribute("aria-invalid", "true")
            False -> attribute.none()
          },
          case has_error {
            True -> attribute.attribute("aria-describedby", error_id)
            False -> attribute.none()
          },
        ],
      ),

      // Error message
      error_message_view(error, error_id),
    ],
  )
}

/// Error message view for a field
fn error_message_view(
  error: Option(FieldError),
  error_id: String,
) -> Element(Msg) {
  case error {
    None -> element.none()
    Some(err) -> {
      let error_text = error_to_string(err)
      let testid = case error_id {
        "store-name-error" -> "name-error-message"
        "store-phone-error" -> "phone-error-message"
        _ -> error_id <> "-message"
      }
      html.div(
        [
          attribute.class("error-message"),
          attribute.id(error_id),
          attribute.attribute("data-testid", testid),
          attribute.attribute("role", "alert"),
        ],
        [element.text(error_text)],
      )
    }
  }
}

/// Submission error banner view
fn submission_error_view(
  error: Option(String),
) -> Element(Msg) {
  case error {
    None -> element.none()
    Some(err) -> {
      html.div(
        [
          attribute.class("submission-error"),
          attribute.class("error-banner"),
          attribute.attribute("data-testid", "submission-error-message"),
          attribute.attribute("role", "alert"),
        ],
        [
          html.strong([], [element.text("Error: ")]),
          element.text(err),
        ],
      )
    }
  }
}

/// Submit button view with loading state
fn submit_button_view(is_submitting: Bool) -> Element(Msg) {
  html.div([attribute.class("form-actions")], [
    html.button(
      [
        attribute.type_("submit"),
        attribute.class("submit-button"),
        attribute.class(case is_submitting {
          True -> "submit-button--loading"
          False -> ""
        }),
        attribute.attribute("data-testid", "submit-store-button"),
        attribute.disabled(is_submitting),
      ],
      [
        element.text(case is_submitting {
          True -> "Creating..."
          False -> "Create Store"
        }),
      ],
    ),
  ])
}

/// Store detail view (shown after successful creation)
fn store_detail_view(store_id: String, store_name: String) -> Element(Msg) {
  html.div([attribute.class("store-detail-container")], [
    html.h1([], [element.text(store_name)]),
    html.p([], [
      element.text("Store ID: " <> store_id),
    ]),
    html.div([attribute.class("store-actions")], [
      html.button(
        [
          attribute.class("back-button"),
          event.on_click(NavigateTo("/stores/new")),
        ],
        [element.text("Create Another Store")],
      ),
    ]),
  ])
}
