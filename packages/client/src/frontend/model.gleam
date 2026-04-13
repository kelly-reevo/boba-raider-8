/// Application state

import frontend/create_drink_form.{type CreateDrinkForm}

pub type Model {
  Model(
    count: Int,
    error: String,
    create_drink_form: CreateDrinkForm,
  )
}

pub fn default() -> Model {
  Model(
    count: 0,
    error: "",
    create_drink_form: create_drink_form.empty_form(),
  )
}
