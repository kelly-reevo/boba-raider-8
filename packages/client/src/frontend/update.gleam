import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}
import shared.{Todo}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Fetch todos
    msg.FetchTodos -> #(
      Model(..model, loading: True, error: ""),
      effects.fetch_todos(),
    )
    msg.FetchTodosSuccess(todos) -> #(
      Model(todos: todos, loading: False, error: "", toggling_id: model.toggling_id),
      effect.none(),
    )
    msg.FetchTodosError(error) -> #(
      Model(..model, loading: False, error: error),
      effect.none(),
    )

    // Alternative loading messages
    msg.LoadTodos -> #(model, effects.fetch_todos())
    msg.TodosLoaded(todos) -> #(Model(..model, todos: todos, loading: False), effect.none())
    msg.TodosLoadFailed(error) -> #(Model(..model, loading: False, error: error), effect.none())

    // Toggle todo with optimistic update
    msg.ToggleTodo(id, completed) -> {
      let updated_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: completed)
          False -> item
        }
      })
      #(Model(..model, todos: updated_todos, toggling_id: id), effects.patch_todo(id, completed))
    }
    msg.ToggleTodoSuccess(item) -> {
      let updated_todos = list.map(model.todos, fn(it) {
        case it.id == item.id {
          True -> item
          False -> it
        }
      })
      #(Model(..model, todos: updated_todos, toggling_id: ""), effect.none())
    }
    msg.ToggleTodoError(id, previous_state, error) -> {
      let reverted_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> Todo(..item, completed: previous_state)
          False -> item
        }
      })
      #(Model(..model, todos: reverted_todos, toggling_id: "", error: error), effect.none())
    }
    msg.TodoUpdated(updated) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated.id {
          True -> updated
          False -> t
        }
      })
      #(Model(..model, todos: new_todos, toggling_id: ""), effect.none())
    }
    msg.TodoUpdateFailed(error) -> #(Model(..model, error: error, toggling_id: ""), effect.none())

    // Delete todo
    msg.DeleteTodo(id) -> #(model, effects.delete_todo(id))
    msg.TodoDeleted(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: new_todos), effect.none())
    }
    msg.TodoDeleteFailed(error) -> #(Model(..model, error: error), effect.none())
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
