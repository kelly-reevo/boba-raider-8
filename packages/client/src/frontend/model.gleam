/// Application state with loading states and error handling

import shared.{type Filter, type Todo, All}

/// Error state for different containers
pub type ErrorState {
  NoError
  Error(message: String, transient: Bool)
}

pub type Model {
  Model(
    // Core data
    todos: List(Todo),
    filter: Filter,

    // Form state
    new_todo_title: String,
    new_todo_description: String,

    // Loading states
    is_loading: Bool,
    is_adding: Bool,
    saving_todo_ids: List(String),
    deleting_todo_ids: List(String),

    // UI text state
    loading_message: String,
    submit_button_text: String,

    // Error states by container
    list_error: ErrorState,
    form_error: ErrorState,
    global_error: ErrorState,

    // Transient error tracking
    transient_error_active: Bool,
  )
}

/// Initial model state
pub fn init() -> Model {
  Model(
    todos: [],
    filter: All,
    new_todo_title: "",
    new_todo_description: "",
    is_loading: True,
    // Start with loading true for initial fetch
    is_adding: False,
    saving_todo_ids: [],
    deleting_todo_ids: [],
    loading_message: "Loading todos...",
    submit_button_text: "Add Todo",
    list_error: NoError,
    form_error: NoError,
    global_error: NoError,
    transient_error_active: False,
  )
}

/// Check if any global loading state is active
pub fn is_globally_loading(model: Model) -> Bool {
  model.is_loading || model.is_adding
}

/// Check if a specific item is being saved (toggle/update)
pub fn is_todo_saving(model: Model, item_id: String) -> Bool {
  list_contains(model.saving_todo_ids, item_id)
}

/// Check if a specific item is being deleted
pub fn is_todo_deleting(model: Model, item_id: String) -> Bool {
  list_contains(model.deleting_todo_ids, item_id)
}

/// Check if a specific item has any operation in progress
pub fn is_todo_busy(model: Model, item_id: String) -> Bool {
  is_todo_saving(model, item_id) || is_todo_deleting(model, item_id)
}

/// Check if there are any errors currently showing
pub fn has_any_error(model: Model) -> Bool {
  case model.list_error, model.form_error, model.global_error {
    NoError, NoError, NoError -> False
    _, _, _ -> True
  }
}

/// Clear all errors (used after successful operations)
pub fn clear_all_errors(model: Model) -> Model {
  Model(
    ..model,
    list_error: NoError,
    form_error: NoError,
    global_error: NoError,
    transient_error_active: False,
  )
}

/// Set list error
pub fn set_list_error(model: Model, message: String, transient: Bool) -> Model {
  Model(
    ..model,
    list_error: Error(message, transient),
    transient_error_active: transient,
  )
}

/// Set form error
pub fn set_form_error(model: Model, message: String) -> Model {
  Model(..model, form_error: Error(message, False))
}

/// Set global error
pub fn set_global_error(model: Model, message: String) -> Model {
  Model(..model, global_error: Error(message, False))
}

/// Clear list error only
pub fn clear_list_error(model: Model) -> Model {
  Model(..model, list_error: NoError, transient_error_active: False)
}

/// Clear form error only
pub fn clear_form_error(model: Model) -> Model {
  Model(..model, form_error: NoError)
}

/// Helper to check if a string is in a list
fn list_contains(list: List(String), item: String) -> Bool {
  case list {
    [] -> False
    [first, ..rest] -> first == item || list_contains(rest, item)
  }
}
