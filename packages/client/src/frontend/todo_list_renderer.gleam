/// Todo list renderer - FFI wrapper for JavaScript DOM manipulation
/// Boundary contract: renderTodos(todos: Todo[]) -> DOM manipulation

import gleam/option.{type Option}

/// Todo item for rendering
pub type RenderableTodo {
  RenderableTodo(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
  )
}

/// Render todos to the DOM list container
/// Creates <li data-id='todo.id'> with checkbox, title, description, priority badge, delete button
@external(javascript, "../../../../server/priv/static/js/todo_list_renderer.js", "renderTodos")
pub fn render_todos(todos: List(RenderableTodo)) -> Nil {
  // Erlang target fallback - no-op since this is browser-only
  Nil
}
