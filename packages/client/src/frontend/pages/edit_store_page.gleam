/// Edit Store Page Component
/// Pre-populated form with same validation as create
/// Only visible to store creator

import frontend/model.{type EditStoreState, can_edit_store}
import frontend/msg.{
  type Msg, EditStoreMsg, SubmitForm, UpdateName, UpdateDescription,
  UpdateAddress, UpdatePhone, UpdateEmail, CancelEdit, ResetForm,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Store, type User, type StoreValidationErrors, type StoreInput, type Option, Some, None}

// Component: EditStorePage
// API: GET /api/stores/:id, PATCH /api/stores/:id
// Guard: user.id === store.created_by
// On success: redirect to /stores/:id

pub fn view(
  state: EditStoreState,
  current_user: shared.Option(User),
) -> Element(Msg) {
  // Authorization guard - only creator can edit
  let is_authorized = can_edit_store(current_user, state.original_store)

  // Determine which state to render
  case state.loading, is_authorized, state.load_error {
    // Loading state
    True, _, _ -> loading_view()

    // Unauthorized - user is not the creator
    False, False, None -> unauthorized_view()

    // Error loading store
    False, _, Some(error) -> error_view(error, state.store_id)

    // Ready - show the form
    False, True, None -> form_view(state)
  }
}

/// Loading state - fetching store data
fn loading_view() -> Element(Msg) {
  html.div([attribute.class("edit-store-page loading")], [
    html.div([attribute.class("loading-indicator")], [
      html.span([], [element.text("Loading store data...")]),
    ]),
  ])
}

/// Unauthorized state - user cannot edit this store
fn unauthorized_view() -> Element(Msg) {
  html.div([attribute.class("edit-store-page unauthorized")], [
    html.h1([], [element.text("Access Denied")]),
    html.p([], [
      element.text("You do not have permission to edit this store. "),
      element.text("Only the store creator can make changes."),
    ]),
    html.a([attribute.href("/stores"), attribute.class("btn-secondary")], [
      element.text("Back to Stores"),
    ]),
  ])
}

/// Error state - failed to load store
fn error_view(error: String, store_id: String) -> Element(Msg) {
  html.div([attribute.class("edit-store-page error")], [
    html.h1([], [element.text("Error Loading Store")]),
    html.p([attribute.class("error-message")], [element.text(error)]),
    html.div([attribute.class("error-actions")], [
      html.a(
        [
          attribute.href("/stores"),
          attribute.class("btn-primary"),
        ],
        [element.text("Back to Stores")],
      ),
      html.a([attribute.href("/stores/" <> store_id), attribute.class("btn-secondary")], [
        element.text("Go to Store"),
      ]),
    ]),
  ])
}

/// Main form view - pre-populated with store data
fn form_view(state: EditStoreState) -> Element(Msg) {
  let submit_button_text = case state.saving {
    True -> "Saving..."
    False -> "Save Changes"
  }

  html.div([attribute.class("edit-store-page")], [
    html.h1([], [element.text("Edit Store")]),

    // Save error banner
    case state.save_error {
      Some(error) ->
        html.div([attribute.class("error-banner")], [
          element.text(error),
        ])
      None -> element.text("")
    },

    html.form(
      [
        attribute.class("store-form"),
        event.on_submit(fn(_form_data) { EditStoreMsg(SubmitForm) }),
      ],
      [
        // Name field
        form_field(
          label: "Store Name",
          name: "name",
          value: state.input.name,
          placeholder: "Enter store name",
          required: True,
          error: state.validation_errors.name,
          on_input: fn(value) { EditStoreMsg(UpdateName(value)) },
        ),

        // Description field
        form_field(
          label: "Description",
          name: "description",
          value: state.input.description,
          placeholder: "Enter store description",
          required: True,
          error: state.validation_errors.description,
          on_input: fn(value) { EditStoreMsg(UpdateDescription(value)) },
        ),

        // Address field
        form_field(
          label: "Address",
          name: "address",
          value: state.input.address,
          placeholder: "Enter store address",
          required: True,
          error: state.validation_errors.address,
          on_input: fn(value) { EditStoreMsg(UpdateAddress(value)) },
        ),

        // Phone field
        form_field_with_type(
          label: "Phone",
          name: "phone",
          value: state.input.phone,
          placeholder: "Enter phone number",
          required: True,
          error: state.validation_errors.phone,
          on_input: fn(value) { EditStoreMsg(UpdatePhone(value)) },
          input_type: "tel",
        ),

        // Email field
        form_field_with_type(
          label: "Email",
          name: "email",
          value: state.input.email,
          placeholder: "Enter contact email",
          required: True,
          error: state.validation_errors.email,
          on_input: fn(value) { EditStoreMsg(UpdateEmail(value)) },
          input_type: "email",
        ),

        // Form actions
        html.div([attribute.class("form-actions")], [
          html.button(
            [
              attribute.type_("submit"),
              attribute.class("btn-primary"),
              attribute.disabled(state.saving),
            ],
            [element.text(submit_button_text)],
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("btn-secondary"),
              event.on_click(EditStoreMsg(CancelEdit)),
              attribute.disabled(state.saving),
            ],
            [element.text("Cancel")],
          ),
          html.button(
            [
              attribute.type_("button"),
              attribute.class("btn-tertiary"),
              event.on_click(EditStoreMsg(ResetForm)),
              attribute.disabled(state.saving),
            ],
            [element.text("Reset")],
          ),
        ]),
      ],
    ),
  ])
}

/// Reusable form field component with validation display (defaults to text input)
fn form_field(
  label label_text: String,
  name name_attr: String,
  value value_attr: String,
  placeholder placeholder_text: String,
  required is_required: Bool,
  error error_option: Option(String),
  on_input on_input_handler: fn(String) -> Msg,
) -> Element(Msg) {
  form_field_with_type(
    label: label_text,
    name: name_attr,
    value: value_attr,
    placeholder: placeholder_text,
    required: is_required,
    error: error_option,
    on_input: on_input_handler,
    input_type: "text",
  )
}

/// Form field with explicit input type
fn form_field_with_type(
  label label_text: String,
  name name_attr: String,
  value value_attr: String,
  placeholder placeholder_text: String,
  required is_required: Bool,
  error error_option: shared.Option(String),
  on_input on_input_handler: fn(String) -> Msg,
  input_type input_type_attr: String,
) -> Element(Msg) {
  let input_attrs = [
    attribute.type_(input_type_attr),
    attribute.name(name_attr),
    attribute.value(value_attr),
    attribute.placeholder(placeholder_text),
    event.on_input(on_input_handler),
  ]

  let input_attrs_with_required = case is_required {
    True -> [attribute.required(True), ..input_attrs]
    False -> input_attrs
  }

  let error_class = case error_option {
    Some(_) -> "field-error"
    None -> ""
  }

  html.div([attribute.class("form-field " <> error_class)], [
    html.label([], [element.text(label_text <> case is_required {
      True -> " *"
      False -> ""
    })]),
    html.input(input_attrs_with_required),
    case error_option {
      Some(error_msg) ->
        html.span([attribute.class("error-text")], [element.text(error_msg)])
      None -> element.text("")
    },
  ])
}

// Re-export for view.gleam to use
pub fn edit_store_view(
  state: EditStoreState,
  current_user: shared.Option(User),
) -> Element(Msg) {
  view(state, current_user)
}
