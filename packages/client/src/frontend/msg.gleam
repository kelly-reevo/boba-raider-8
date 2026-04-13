/// Application messages

import frontend/error_types.{type ApiError, type FieldValidationError}

pub type Msg {
  Increment
  Decrement
  Reset
  // Error handling messages
  ApiError(ApiError)
  ClearError
  RetryOperation
  GoBack
  // Loading state
  SetLoading(Bool)
  // Validation
  SetValidationErrors(List(FieldValidationError))
  ClearValidationErrors
}
