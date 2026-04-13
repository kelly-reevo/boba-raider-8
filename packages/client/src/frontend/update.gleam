import frontend/model.{type Model, type ErrorState, type ValidationError, NoError, GeneralErrorState, ValidationErrorState, ValidationError as ValidationErrorConstructor}
import frontend/msg.{type Msg, type ApiError, GeneralApiError, ValidationApiError, NetworkError}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages
    msg.Increment -> #(model.Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(model.Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(model.Model(..model, count: 0), effect.none())

    // Clear error message
    msg.ClearError -> #(model.Model(..model, error: NoError), effect.none())

    // Fetch operations - success clears errors
    msg.FetchTodos -> #(model, effect.none())
    msg.FetchTodosSuccess(_) -> #(model.Model(..model, error: NoError), effect.none())
    msg.FetchTodosError(message) -> #(model.Model(..model, error: GeneralErrorState(message)), effect.none())

    // Create operations - handles both general and validation errors
    msg.CreateTodo -> #(model, effect.none())
    msg.CreateTodoSuccess(_) -> #(model.Model(..model, error: NoError), effect.none())
    msg.CreateTodoError(api_error) -> {
      let error_state = convert_api_error_to_state(api_error)
      #(model.Model(..model, error: error_state), effect.none())
    }

    // Update operations - success clears errors
    msg.UpdateTodo(_) -> #(model, effect.none())
    msg.UpdateTodoSuccess(_) -> #(model.Model(..model, error: NoError), effect.none())
    msg.UpdateTodoError(message) -> #(model.Model(..model, error: GeneralErrorState(message)), effect.none())

    // Delete operations - success clears errors
    msg.DeleteTodo(_) -> #(model, effect.none())
    msg.DeleteTodoSuccess(_) -> #(model.Model(..model, error: NoError), effect.none())
    msg.DeleteTodoError(message) -> #(model.Model(..model, error: GeneralErrorState(message)), effect.none())
  }
}

/// Convert API error to error state for the model
fn convert_api_error_to_state(api_error: ApiError) -> ErrorState {
  case api_error {
    GeneralApiError(message) -> GeneralErrorState(message)
    ValidationApiError(errors) -> {
      let validation_errors = convert_validation_pairs(errors)
      ValidationErrorState(validation_errors)
    }
    NetworkError -> GeneralErrorState("Network error. Please check your connection and try again.")
  }
}

/// Convert list of #(field, message) pairs to ValidationError records
fn convert_validation_pairs(pairs: List(#(String, String))) -> List(ValidationError) {
  case pairs {
    [] -> []
    [#(field, message), ..rest] -> [
      ValidationErrorConstructor(field: field, message: message),
      ..convert_validation_pairs(rest)
    ]
  }
}

/// Helper function to display an error from an HTTP response status and message
pub fn error_from_response(status: Int, message: String) -> ApiError {
  case status {
    422 -> GeneralApiError(message)
    _ if status >= 500 -> GeneralApiError(message)
    _ -> GeneralApiError("An error occurred. Please try again.")
  }
}

/// Create a validation error from field errors
pub fn validation_error(field_errors: List(#(String, String))) -> ApiError {
  ValidationApiError(field_errors)
}
