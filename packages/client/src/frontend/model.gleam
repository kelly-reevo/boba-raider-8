/// Application state

/// General error message type
pub type GeneralError {
  GeneralError(message: String)
}

/// Field-specific validation error
pub type ValidationError {
  ValidationError(field: String, message: String)
}

/// Error state that can be either general or validation errors
pub type ErrorState {
  NoError
  GeneralErrorState(String)
  ValidationErrorState(List(ValidationError))
}

pub type Model {
  Model(
    count: Int,
    error: ErrorState,
  )
}

pub fn default() -> Model {
  Model(count: 0, error: NoError)
}
