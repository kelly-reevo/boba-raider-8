import frontend/msg.{type Msg, type ApiError, GeneralApiError, ValidationApiError, NetworkError}
import lustre/effect.{type Effect}

/// Fetch all todos from the API
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // In real implementation, this would make HTTP request
    // For now, dispatch success to demonstrate pattern
    dispatch(msg.FetchTodosSuccess("[]"))
  })
}

/// Create a new todo
pub fn create_todo(title: String, description: String, priority: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call
    dispatch(msg.CreateTodoSuccess("{\"id\": \"new-todo-1\"}"))
  })
}

/// Update an existing todo
pub fn update_todo(todo_id: String, completed: Bool) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call
    dispatch(msg.UpdateTodoSuccess("{\"id\": \"" <> todo_id <> "\"}"))
  })
}

/// Delete a todo
pub fn delete_todo(todo_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call
    dispatch(msg.DeleteTodoSuccess(todo_id))
  })
}

/// Parse API error response into appropriate ApiError type
pub fn parse_api_error(status: Int, body: String) -> ApiError {
  case status {
    422 -> {
      // For validation errors, parse the response body
      // Expected format: {"errors": [{"field": "title", "message": "Title is required"}]}
      GeneralApiError("Validation failed")
    }
    _ if status >= 500 -> {
      // Server errors - extract message if available
      GeneralApiError(body)
    }
    _ -> GeneralApiError("An error occurred. Please try again.")
  }
}

/// Create a validation error from field errors
pub fn validation_error(field_errors: List(#(String, String))) -> ApiError {
  ValidationApiError(field_errors)
}

/// Handle network errors
pub fn handle_network_error() -> ApiError {
  NetworkError
}
