/// Application state

import shared.{type TeaType, Black}

/// Form state for creating a drink
pub type DrinkFormState {
  Idle
  UploadingImage
  ImageUploadError(String)
  Submitting
  SubmitError(String)
  Success
}

/// Form data for drink creation
pub type DrinkFormData {
  DrinkFormData(
    name: String,
    tea_type: TeaType,
    price: String,
    description: String,
    image_file: String,
    image_url: String,
    is_signature: Bool,
  )
}

/// Main application model
pub type Model {
  Model(
    count: Int,
    error: String,
    store_id: String,
    show_create_form: Bool,
    form_data: DrinkFormData,
    form_state: DrinkFormState,
  )
}

/// Default empty form data
fn default_form_data() -> DrinkFormData {
  DrinkFormData(
    name: "",
    tea_type: Black,
    price: "",
    description: "",
    image_file: "",
    image_url: "",
    is_signature: False,
  )
}

/// Default model state
pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    store_id: "",
    show_create_form: False,
    form_data: default_form_data(),
    form_state: Idle,
  )
}

/// Reset form to initial state
pub fn reset_form(model: Model) -> Model {
  Model(
    ..model,
    form_data: default_form_data(),
    form_state: Idle,
  )
}

/// Show the create drink form
pub fn open_form(model: Model, store_id: String) -> Model {
  Model(
    ..model,
    store_id: store_id,
    show_create_form: True,
    form_data: default_form_data(),
    form_state: Idle,
  )
}

/// Close the create drink form
pub fn close_form(model: Model) -> Model {
  Model(..model, show_create_form: False, form_state: Idle)
}
