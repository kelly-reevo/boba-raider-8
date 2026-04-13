/// Application state for todo list UI

import gleam/list
import gleam/option.{type Option, None}
import shared.{type Todo, type Priority, Medium}

/// Filter options for todos
pub type Filter {
  All
  Active
  Completed
}

/// Form state for creating new todos
pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: Priority,
  )
}

/// Data loading state
pub type DataState {
  Loading
  Loaded
  Error(String)
}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Submitting
  Success
  Error(String)
}

/// Application model
pub type Model {
  Model(
    todos: List(Todo),
    filter: Filter,
    data_state: DataState,
    form: FormState,
    submit_state: LoadingState,
    error: String,
    deleting_id: Option(String),
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    filter: All,
    data_state: Loading,
    form: FormState(
      title: "",
      description: "",
      priority: Medium,
    ),
    submit_state: Idle,
    error: "",
    deleting_id: None,
  )
}

/// Filter todos based on current filter setting
pub fn filter_todos(todos: List(Todo), filter: Filter) -> List(Todo) {
  case filter {
    All -> todos
    Active -> list.filter(todos, fn(t) { !t.completed })
    Completed -> list.filter(todos, fn(t) { t.completed })
  }
}

/// Reset form to initial state
pub fn reset_form(model: Model) -> Model {
  Model(
    ..model,
    form: FormState(
      title: "",
      description: "",
      priority: Medium,
    ),
    error: "",
    submit_state: Idle,
  )
}

/// Update form title
pub fn update_form_title(model: Model, title: String) -> Model {
  Model(..model, form: FormState(..model.form, title: title))
}

/// Update form description
pub fn update_form_description(model: Model, description: String) -> Model {
  Model(..model, form: FormState(..model.form, description: description))
}

/// Update form priority
pub fn update_form_priority(model: Model, priority: Priority) -> Model {
  Model(..model, form: FormState(..model.form, priority: priority))
}

/// Set error message
pub fn set_error(model: Model, error: String) -> Model {
  Model(..model, error: error, submit_state: Error(error))
}

/// Clear error message
pub fn clear_error(model: Model) -> Model {
  Model(..model, error: "", submit_state: Idle)
}

/// Set submitting state
pub fn set_submitting(model: Model) -> Model {
  Model(..model, submit_state: Submitting)
}

/// Update todos list
pub fn update_todos(model: Model, todos: List(Todo)) -> Model {
  Model(..model, todos: todos)
}

/// Remove a todo by ID from the list
pub fn remove_todo(model: Model, id: String) -> Model {
  Model(
    ..model,
    todos: list.filter(model.todos, fn(item) { item.id != id }),
    deleting_id: None,
  )
}

/// Set the ID currently being deleted
pub fn set_deleting(model: Model, id: String) -> Model {
  Model(..model, deleting_id: option.Some(id))
}
