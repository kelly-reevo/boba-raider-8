/// Application state

import frontend/error_types.{type ApiError}
import gleam/option.{type Option}

pub type Model {
  Model(
    count: Int,
    error: Option(ApiError),
    is_loading: Bool,
    validation_errors: List(error_types.FieldValidationError),
  )
}

pub fn default() -> Model {
  Model(
    count: 0,
    error: option.None,
    is_loading: False,
    validation_errors: [],
  )
}
