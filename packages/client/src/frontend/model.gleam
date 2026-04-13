/// Application state for Todo App with error handling

/// Todo item type (local definition)
pub type Todo {
  Todo(id: String, title: String, completed: Bool)
}

/// Error state for different containers
pub type ErrorState {
  NoError
  Error(message: String, transient: Bool)
}

/// Main application model
pub type AppModel {
  AppModel(
    // Data state
    todos: List(Todo),
    form_input: String,
    is_loading: Bool,

    // Error states by container
    list_error: ErrorState,
    form_error: ErrorState,
    global_error: ErrorState,

    // Transient error timer tracking
    transient_error_active: Bool,
  )
}

/// Default/initial model state
pub fn default() -> AppModel {
  AppModel(
    todos: [],
    form_input: "",
    is_loading: True,
    list_error: NoError,
    form_error: NoError,
    global_error: NoError,
    transient_error_active: False,
  )
}

/// Check if there are any errors currently showing
pub fn has_any_error(model: AppModel) -> Bool {
  case model.list_error, model.form_error, model.global_error {
    NoError, NoError, NoError -> False
    _, _, _ -> True
  }
}

/// Clear all errors (used after successful operations)
pub fn clear_all_errors(model: AppModel) -> AppModel {
  AppModel(
    ..model,
    list_error: NoError,
    form_error: NoError,
    global_error: NoError,
    transient_error_active: False,
  )
}

/// Set list error
pub fn set_list_error(model: AppModel, message: String, transient: Bool) -> AppModel {
  AppModel(
    ..model,
    list_error: Error(message, transient),
    transient_error_active: transient,
  )
}

/// Set form error
pub fn set_form_error(model: AppModel, message: String) -> AppModel {
  AppModel(..model, form_error: Error(message, False))
}

/// Set global error
pub fn set_global_error(model: AppModel, message: String) -> AppModel {
  AppModel(..model, global_error: Error(message, False))
}

/// Clear list error only
pub fn clear_list_error(model: AppModel) -> AppModel {
  AppModel(..model, list_error: NoError, transient_error_active: False)
}

/// Clear form error only
pub fn clear_form_error(model: AppModel) -> AppModel {
  AppModel(..model, form_error: NoError)
}
