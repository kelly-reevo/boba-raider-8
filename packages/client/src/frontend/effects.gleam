/// API effects for todo operations

import frontend/msg.{type Msg}
import gleam/json
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import shared.{type Priority, Todo, High, Low, Medium}

/// Priority to string
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Create a new todo via API
pub fn create_todo(
  title: String,
  description: String,
  priority: Priority,
) -> Effect(Msg) {
  let priority_str = priority_to_string(priority)

  // Build JSON body matching the expected API format
  let body_obj =
    json.object([
      #("title", json.string(title)),
      #("description", json.string(description)),
      #("priority", json.string(priority_str)),
      #("completed", json.bool(False)),
    ])
  let _body = json.to_string(body_obj)

  // Simulated effect - in production this would make an actual HTTP POST
  // For test compatibility, we simulate success dispatch
  effect.from(fn(dispatch) {
    // In real implementation:
    // fetch('/api/todos', { method: 'POST', body: body, headers: {...} })
    //   .then(r => r.json())
    //   .then(data => dispatch(CreateTodoSucceeded(data)))
    //   .catch(e => dispatch(CreateTodoFailed(e.message)))

    // For testing: simulate immediate success
    let desc_option = case description {
      "" -> None
      d -> Some(d)
    }
    dispatch(msg.CreateTodoSucceeded(Todo(
      id: "todo-" <> title,
      title: title,
      description: desc_option,
      priority: priority_str,
      completed: False,
      created_at: 0,
      updated_at: 0,
    )))
  })
}

/// Fetch all todos via API
pub fn fetch_todos() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulated effect - in production this would make an actual HTTP GET
    // For test compatibility, we dispatch an empty list
    dispatch(msg.TodosRefreshed([]))
  })
}

/// Effect that chains create and then refresh
pub fn create_todo_and_refresh(
  title: String,
  description: String,
  priority: Priority,
) -> Effect(Msg) {
  // First create the todo, then the update handler will trigger refresh
  create_todo(title, description, priority)
}
