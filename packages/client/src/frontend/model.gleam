/// Application state for todo app with loading states

import frontend/msg.{type OperationLoading, CreateLoading, DeleteLoading, ListLoading, UpdateLoading}
import gleam/list
import gleam/option.{type Option, None, Some}
import shared.{type Todo}

/// Application model with todos and loading states
pub type Model {
  Model(
    todos: List(Todo),
    error: Option(String),
    loading_operations: List(OperationLoading),
    form_title: String,
    form_description: String,
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    error: None,
    loading_operations: [],
    form_title: "",
    form_description: "",
  )
}

/// Check if list is currently loading
pub fn is_list_loading(model: Model) -> Bool {
  list.any(model.loading_operations, fn(op) {
    case op {
      ListLoading -> True
      _ -> False
    }
  })
}

/// Check if create operation is in progress
pub fn is_creating(model: Model) -> Bool {
  list.any(model.loading_operations, fn(op) {
    case op {
      CreateLoading -> True
      _ -> False
    }
  })
}

/// Check if a specific todo is being updated
pub fn is_updating(model: Model, todo_id: String) -> Bool {
  list.any(model.loading_operations, fn(op) {
    case op {
      UpdateLoading(id) if id == todo_id -> True
      _ -> False
    }
  })
}

/// Check if a specific todo is being deleted
pub fn is_deleting(model: Model, todo_id: String) -> Bool {
  list.any(model.loading_operations, fn(op) {
    case op {
      DeleteLoading(id) if id == todo_id -> True
      _ -> False
    }
  })
}

/// Add a loading operation to the model
pub fn add_loading(model: Model, operation: OperationLoading) -> Model {
  Model(..model, loading_operations: [operation, ..model.loading_operations])
}

/// Remove a loading operation from the model
pub fn remove_loading(model: Model, operation: OperationLoading) -> Model {
  Model(
    ..model,
    loading_operations: list.filter(model.loading_operations, fn(op) { op != operation }),
  )
}

/// Clear error message
pub fn clear_error(model: Model) -> Model {
  Model(..model, error: None)
}

/// Set error message
pub fn set_error(model: Model, error_msg: String) -> Model {
  Model(..model, error: Some(error_msg))
}
