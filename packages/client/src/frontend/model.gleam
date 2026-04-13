/// Application state with loading state management

import shared.{type Filter, type Todo, All}

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

    // Error state
    error: String,
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
    error: "",
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

/// Helper to check if a string is in a list
fn list_contains(list: List(String), item: String) -> Bool {
  case list {
    [] -> False
    [first, ..rest] -> first == item || list_contains(rest, item)
  }
}
