/// Application state

import shared.{type Todo, type Priority, Medium}

/// Form state for creating new todos
pub type FormState {
  FormState(
    title: String,
    description: String,
    priority: Priority,
  )
}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Success
  Error(String)
}

/// Main application model
pub type Model {
  Model(
    todos: List(Todo),
    form: FormState,
    submit_state: LoadingState,
    error: String,
  )
}

/// Default initial state
pub fn default() -> Model {
  Model(
    todos: [],
    form: FormState(
      title: "",
      description: "",
      priority: Medium,
    ),
    submit_state: Idle,
    error: "",
  )
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

/// Set loading state
pub fn set_loading(model: Model) -> Model {
  Model(..model, submit_state: Loading)
}

/// Update todos list
pub fn update_todos(model: Model, todos: List(Todo)) -> Model {
  Model(..model, todos: todos)
}
