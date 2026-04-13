/// Application state with loading states

pub type LoadingState {
  Idle
  Loading
  Success
  Error(String)
}

pub type Todo {
  Todo(id: String, title: String, description: String, completed: Bool)
}

pub type Model {
  Model(
    // List loading state
    list_loading: LoadingState,
    // Form submission loading state
    form_loading: LoadingState,
    // Individual todo operation loading states (by id)
    todo_loading: Dict(String, LoadingState),
    // Data
    todos: List(Todo),
    // Error message
    error: String,
    // Form fields
    title_input: String,
    description_input: String,
  )
}

import gleam/dict.{type Dict}

pub fn default() -> Model {
  Model(
    list_loading: Idle,
    form_loading: Idle,
    todo_loading: dict.new(),
    todos: [],
    error: "",
    title_input: "",
    description_input: "",
  )
}

/// Check if any loading operation is in progress
pub fn is_loading(model: Model) -> Bool {
  case model.list_loading {
    Loading -> True
    _ -> False
  }
}

/// Check if form is submitting
pub fn is_form_submitting(model: Model) -> Bool {
  case model.form_loading {
    Loading -> True
    _ -> False
  }
}

/// Check if a specific todo is being operated on
pub fn is_todo_loading(model: Model, todo_id: String) -> Bool {
  case dict.get(model.todo_loading, todo_id) {
    Ok(Loading) -> True
    _ -> False
  }
}

/// Set loading state for the list
pub fn set_list_loading(model: Model, loading: LoadingState) -> Model {
  Model(..model, list_loading: loading)
}

/// Set loading state for the form
pub fn set_form_loading(model: Model, loading: LoadingState) -> Model {
  Model(..model, form_loading: loading)
}

/// Set loading state for a specific todo
pub fn set_todo_loading(model: Model, todo_id: String, loading: LoadingState) -> Model {
  Model(..model, todo_loading: dict.insert(model.todo_loading, todo_id, loading))
}

/// Clear error message
pub fn clear_error(model: Model) -> Model {
  Model(..model, error: "")
}

/// Set error message
pub fn set_error(model: Model, error: String) -> Model {
  Model(..model, error: error, list_loading: Error(error))
}

/// Update todos list
pub fn set_todos(model: Model, todos: List(Todo)) -> Model {
  Model(..model, todos: todos, list_loading: Success)
}

/// Add a new todo to the list
pub fn add_todo(model: Model, item: Todo) -> Model {
  Model(..model, todos: [item, ..model.todos], form_loading: Success, title_input: "", description_input: "")
}

/// Update a todo in the list
pub fn update_todo(model: Model, updated: Todo) -> Model {
  let new_todos = model.todos |> list.map(fn(t) {
    case t.id == updated.id {
      True -> updated
      False -> t
    }
  })
  let new_loading = dict.delete(model.todo_loading, updated.id)
  Model(..model, todos: new_todos, todo_loading: new_loading)
}

/// Remove a todo from the list
pub fn remove_todo(model: Model, todo_id: String) -> Model {
  let new_todos = model.todos |> list.filter(fn(t) { t.id != todo_id })
  let new_loading = dict.delete(model.todo_loading, todo_id)
  Model(..model, todos: new_todos, todo_loading: new_loading)
}

/// Update title input
pub fn set_title_input(model: Model, value: String) -> Model {
  Model(..model, title_input: value)
}

/// Update description input
pub fn set_description_input(model: Model, value: String) -> Model {
  Model(..model, description_input: value)
}

// Import list at the end to avoid circular reference issues in type definitions
import gleam/list
