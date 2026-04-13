import frontend/effects
import frontend/model.{
  type ErrorState, type Filter, type LoadingState, type Model, type RetryAction,
  FormState, Idle, Loading, Saving, Deleting, All, Active, Completed, FetchTodos,
  CreateTodo, UpdateTodo, DeleteTodo, NetworkError, ValidationError, GenericError,
}
import frontend/msg.{type ApiError, type Msg}
import gleam/dict
import gleam/int
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Priority, type Todo}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Filter messages - client-side only, no API call
    msg.SetFilter(filter) -> #(
      model.Model(..model, filter: filter),
      effect.none(),
    )

    // Form interactions
    msg.FormTitleChanged(title) -> #(
      model.Model(..model, form: FormState(..model.form, title: title)),
      effect.none(),
    )
    msg.FormDescriptionChanged(description) -> #(
      model.Model(..model, form: FormState(..model.form, description: description)),
      effect.none(),
    )
    msg.FormPriorityChanged(priority) -> #(
      model.Model(..model, form: FormState(..model.form, priority: priority)),
      effect.none(),
    )
    msg.FormSubmit -> {
      let desc = case model.form.description {
        "" -> None
        d -> Some(d)
      }
      let retry = CreateTodo(model.form.title, desc, model.form.priority)
      #(
        model.Model(..model, loading: Saving, error: None, retry_action: Some(retry)),
        effects.create_todo(model.form.title, desc, model.form.priority),
      )
    }
    msg.FormReset -> #(
      model.Model(..model, form: FormState(title: "", description: "", priority: shared.Medium)),
      effect.none(),
    )

    // Todo actions - start loading with retry action set
    msg.FetchTodos -> {
      let retry = FetchTodos
      #(
        model.Model(..model, loading: Loading, error: None, retry_action: Some(retry)),
        effects.fetch_todos(),
      )
    }
    msg.CreateTodo(title, description, priority) -> {
      let desc = case description {
        "" -> None
        d -> Some(d)
      }
      let retry = CreateTodo(title, desc, priority)
      #(
        model.Model(..model, loading: Saving, error: None, retry_action: Some(retry)),
        effects.create_todo(title, desc, priority),
      )
    }
    msg.UpdateTodo(id, title, description, completed) -> {
      let desc = case description {
        "" -> None
        d -> Some(d)
      }
      let retry = UpdateTodo(id, title, desc, completed)
      #(
        model.Model(..model, loading: Saving, error: None, retry_action: Some(retry)),
        effects.update_todo(id, title, desc, completed),
      )
    }
    msg.DeleteTodo(id) -> {
      let retry = DeleteTodo(id)
      #(
        model.Model(..model, loading: Deleting, error: None, retry_action: Some(retry)),
        effects.delete_todo(id),
      )
    }
    msg.ToggleTodo(id, completed) -> {
      // Find the todo to get its title/description for the retry action
      let found_todo = find_todo(model.todos, id)
      let retry = case found_todo {
        Some(t) -> UpdateTodo(id, t.title, t.description, completed)
        None -> UpdateTodo(id, "", None, completed)
      }
      #(
        model.Model(..model, loading: Saving, error: None, retry_action: Some(retry)),
        effects.toggle_todo(id, completed),
      )
    }

    // API responses - clear error on success
    msg.FetchTodosSuccess(todos) -> #(
      model.Model(
        ..model,
        todos: todos,
        loading: Idle,
        error: None,
        retry_action: None,
      ),
      effect.none(),
    )
    msg.FetchTodosError(error) -> {
      let error_state = api_error_to_error_state(error)
      let is_retryable = case error {
        msg.NetworkError -> True
        _ -> False
      }
      let retry = case is_retryable {
        True -> model.retry_action
        False -> None
      }
      #(
        model.Model(
          ..model,
          loading: Idle,
          error: Some(error_state),
          retry_action: retry,
        ),
        effect.none(),
      )
    }
    msg.CreateTodoSuccess(todo_item) -> #(
      model.Model(
        ..model,
        todos: [todo_item, ..model.todos],
        form: FormState(title: "", description: "", priority: shared.Medium),
        loading: Idle,
        error: None,
        retry_action: None,
      ),
      effect.none(),
    )
    msg.CreateTodoError(error) -> {
      let error_state = api_error_to_error_state(error)
      let is_retryable = case error {
        msg.NetworkError -> True
        _ -> False
      }
      let retry = case is_retryable {
        True -> model.retry_action
        False -> None
      }
      #(
        model.Model(
          ..model,
          loading: Idle,
          error: Some(error_state),
          retry_action: retry,
        ),
        effect.none(),
      )
    }
    msg.UpdateTodoSuccess(updated_todo) -> {
      let new_todos = update_todo_in_list(model.todos, updated_todo)
      #(
        model.Model(
          ..model,
          todos: new_todos,
          loading: Idle,
          error: None,
          retry_action: None,
        ),
        effect.none(),
      )
    }
    msg.UpdateTodoError(error) -> {
      let error_state = api_error_to_error_state(error)
      let is_retryable = case error {
        msg.NetworkError -> True
        _ -> False
      }
      let retry = case is_retryable {
        True -> model.retry_action
        False -> None
      }
      #(
        model.Model(
          ..model,
          loading: Idle,
          error: Some(error_state),
          retry_action: retry,
        ),
        effect.none(),
      )
    }
    msg.DeleteTodoSuccess(id) -> {
      let new_todos = remove_todo_from_list(model.todos, id)
      #(
        model.Model(
          ..model,
          todos: new_todos,
          loading: Idle,
          error: None,
          retry_action: None,
        ),
        effect.none(),
      )
    }
    msg.DeleteTodoError(error, _id) -> {
      let error_state = api_error_to_error_state(error)
      let is_retryable = case error {
        msg.NetworkError -> True
        _ -> False
      }
      let retry = case is_retryable {
        True -> model.retry_action
        False -> None
      }
      #(
        model.Model(
          ..model,
          loading: Idle,
          error: Some(error_state),
          retry_action: retry,
        ),
        effect.none(),
      )
    }

    // Error handling
    msg.RetryAction -> {
      case model.retry_action {
        Some(retry) -> retry_operation(model, retry)
        None -> #(model, effect.none())
      }
    }
    msg.ClearError -> #(
      model.Model(..model, error: None, retry_action: None),
      effect.none(),
    )
    msg.DismissFieldError(field) -> {
      case model.error {
        Some(error) -> {
          let new_field_errors = dict.delete(error.field_errors, field)
          let new_error = case dict.size(new_field_errors) {
            0 -> None
            _ -> Some(model.ErrorState(..error, field_errors: new_field_errors))
          }
          #(
            model.Model(..model, error: new_error),
            effect.none(),
          )
        }
        None -> #(model, effect.none())
      }
    }
  }
}

/// Convert API error to error state
fn api_error_to_error_state(error: ApiError) -> ErrorState {
  case error {
    msg.NetworkError -> {
      model.ErrorState(
        message: "Failed to load todos. Check your connection and retry.",
        error_type: NetworkError,
        field_errors: dict.new(),
      )
    }
    msg.ServerError(422) -> {
      model.ErrorState(
        message: "Please fix the errors below.",
        error_type: model.ValidationError,
        field_errors: dict.new(),
      )
    }
    msg.ServerError(status) -> {
      model.ErrorState(
        message: "Server error (" <> int_to_string(status) <> "). Please try again later.",
        error_type: GenericError,
        field_errors: dict.new(),
      )
    }
    msg.ValidationError(field_errors) -> {
      model.ErrorState(
        message: "Please fix the errors below.",
        error_type: model.ValidationError,
        field_errors: field_errors,
      )
    }
  }
}

/// Retry a failed operation
fn retry_operation(model: Model, retry: RetryAction) -> #(Model, Effect(Msg)) {
  case retry {
    FetchTodos -> {
      #(
        model.Model(..model, loading: Loading, error: None),
        effects.fetch_todos(),
      )
    }
    CreateTodo(title, description, priority) -> {
      #(
        model.Model(..model, loading: Saving, error: None),
        effects.create_todo(title, description, priority),
      )
    }
    UpdateTodo(id, title, description, completed) -> {
      #(
        model.Model(..model, loading: Saving, error: None),
        effects.update_todo(id, title, description, completed),
      )
    }
    DeleteTodo(id) -> {
      #(
        model.Model(..model, loading: Deleting, error: None),
        effects.delete_todo(id),
      )
    }
  }
}

/// Find a todo by ID
fn find_todo(todos: List(Todo), id: String) -> Option(Todo) {
  case todos {
    [] -> None
    [first, ..rest] -> {
      case first.id == id {
        True -> Some(first)
        False -> find_todo(rest, id)
      }
    }
  }
}

/// Update a todo in the list
fn update_todo_in_list(todos: List(Todo), updated: Todo) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] -> {
      case first.id == updated.id {
        True -> [updated, ..rest]
        False -> [first, ..update_todo_in_list(rest, updated)]
      }
    }
  }
}

/// Remove a todo from the list
fn remove_todo_from_list(todos: List(Todo), id: String) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] -> {
      case first.id == id {
        True -> rest
        False -> [first, ..remove_todo_from_list(rest, id)]
      }
    }
  }
}

/// Convert int to string helper
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> int.to_string(n)
  }
}
