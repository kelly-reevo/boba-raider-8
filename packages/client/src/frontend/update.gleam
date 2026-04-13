import frontend/model.{
  type Model, type Page,
  Model, CreateStoreForm, CreateStorePage, StoreDetailPage,
  update_field, validate_form, has_errors,
}
import frontend/msg.{type Msg, type Field,
  Increment, Decrement, Reset,
  UpdateField, SubmitForm, CreateStoreSuccess, CreateStoreError,
  NavigateTo, PageChanged,
  NameField, AddressField, CityField, PhoneField,
}
import frontend/effects
import lustre/effect.{type Effect}
import gleam/option.{type Option, None, Some}
import gleam/string

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Legacy counter messages
    Increment -> #(Model(..model, count: model.count + 1), effect.none())
    Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    Reset -> #(Model(..model, count: 0), effect.none())

    // Form field updates
    UpdateField(field, value) -> {
      let field_name = field_to_string(field)
      let new_form = update_field(model.create_store_form, field_name, value)
      #(Model(..model, create_store_form: new_form), effect.none())
    }

    // Form submission
    SubmitForm -> handle_submit(model)

    // Create store API response handlers
    CreateStoreSuccess(store_id, _name) -> {
      // Navigate to the new store page
      let new_model = Model(..model, page: StoreDetailPage(store_id))
      #(new_model, effect.from(fn(_) { navigate_to_store(store_id) }))
    }

    CreateStoreError(error) -> {
      let new_form = CreateStoreForm(
        ..model.create_store_form,
        is_submitting: False,
        submission_error: Some(error),
      )
      #(Model(..model, create_store_form: new_form), effect.none())
    }

    // Navigation
    NavigateTo(path) -> {
      let new_page = parse_page(path)
      #(Model(..model, page: new_page), effect.from(fn(_) { navigate_js(path) }))
    }

    PageChanged(path) -> {
      let new_page = parse_page(path)
      #(Model(..model, page: new_page), effect.none())
    }
  }
}

/// Handle form submission
fn handle_submit(model: Model) -> #(Model, Effect(Msg)) {
  let form = model.create_store_form

  // Validate form
  let errors = validate_form(form)

  case has_errors(errors) {
    True -> {
      // Validation failed - show errors, don't submit
      let new_form = CreateStoreForm(
        ..form,
        errors: errors,
        is_submitting: False,
        submission_error: None,
      )
      #(Model(..model, create_store_form: new_form), effect.none())
    }
    False -> {
      // Validation passed - submit to API
      let new_form = CreateStoreForm(
        ..form,
        is_submitting: True,
        submission_error: None,
      )
      let effect = effects.submit_create_store(
        form.fields.name |> string.trim,
        form.fields.address |> string.trim,
        form.fields.city |> string.trim,
        form.fields.phone |> string.trim,
      )
      #(Model(..model, create_store_form: new_form), effect)
    }
  }
}

/// Convert field type to string
fn field_to_string(field: Field) -> String {
  case field {
    NameField -> "name"
    AddressField -> "address"
    CityField -> "city"
    PhoneField -> "phone"
  }
}

/// Parse URL path to page
fn parse_page(path: String) -> Page {
  case path {
    "/stores/new" -> CreateStorePage
    "/" -> CreateStorePage  // Default to create store for now
    _ -> {
      // Check if it's a store detail page
      case string.starts_with(path, "/stores/") {
        True -> {
          let store_id = string.slice(path, 8, string.length(path) - 8)
          StoreDetailPage(store_id)
        }
        False -> CreateStorePage
      }
    }
  }
}

/// Navigate to store detail page via JavaScript
fn navigate_to_store(store_id: String) {
  let path = "/stores/" <> store_id
  navigate_js(path)
}

/// JavaScript FFI for navigation
@external(javascript, "./effects_ffi.mjs", "navigate")
fn navigate_js(path: String) -> Nil
