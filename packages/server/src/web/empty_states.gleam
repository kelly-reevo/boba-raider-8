/// Empty states rendering module
/// Displays contextual messages when no todos are visible

import gleam/list
import todo_item.{type TodoItem}

/// Render empty state HTML based on todos list and current filter
/// Returns HTML string for the empty state component
pub fn render(todos: List(TodoItem), filter: String) -> String {
  case list.is_empty(todos) {
    True -> {
      // Todos list is empty - show contextual empty state
      let message = case filter {
        "active" -> "No active todos"
        "completed" -> "No completed todos"
        _ -> "No todos yet. Create one above!"
      }
      render_empty_state_html(message)
    }
    False -> {
      // Todos exist - render the list container, empty state is hidden
      "<div class='todo-list'></div>"
    }
  }
}

/// Generate the empty state HTML with given message
fn render_empty_state_html(message: String) -> String {
  "<div class='empty-state'><p>" <> message <> "</p></div>"
}
