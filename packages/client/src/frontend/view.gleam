/// View functions for todo list display
/// Renders: loading, empty, error, and populated states
/// Each todo has: data-todo-id, .todo-title, .todo-description (optional),
/// .todo-priority, .todo-checkbox, .todo-delete-btn

import frontend/model
import frontend/msg.{type Msg}
import gleam/option
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Priority, type Todo, High, Low, Medium}

/// Main view function
pub fn view(model: model.Model) -> Element(Msg) {
  html.div([attribute.id("app")], [
    html.h1([], [element.text("Todo List")]),
    render_todo_list(model),
  ])
}

/// Render the todo list container with appropriate state
fn render_todo_list(model: model.Model) -> Element(Msg) {
  html.ul([attribute.id("todo-list")], case model.loading {
    model.Idle -> []
    model.Loading -> [render_loading()]
    model.Error(err) -> [render_error(err)]
    model.Success -> {
      case model.todos {
        [] -> [render_empty()]
        todos -> list.map(todos, render_todo)
      }
    }
  })
}

/// Loading state indicator
fn render_loading() -> Element(Msg) {
  html.li(
    [attribute.class("loading-state")],
    [element.text("Loading todos...")],
  )
}

/// Empty state when no todos exist
fn render_empty() -> Element(Msg) {
  html.li(
    [attribute.class("empty-state")],
    [element.text("No todos yet. Add one above!")],
  )
}

/// Error state display
fn render_error(error: String) -> Element(Msg) {
  html.li(
    [attribute.class("error-state")],
    [element.text("Error: " <> error)],
  )
}

/// Render a single todo item with all required elements
fn render_todo(todo_item: Todo) -> Element(Msg) {
  html.li(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-todo-id", todo_item.id),
    ],
    [
      // Title
      html.span([attribute.class("todo-title")], [element.text(todo_item.title)]),
      // Priority badge with color-coded class
      html.span(
        [
          attribute.class("todo-priority priority-" <> priority_to_class(todo_item.priority)),
        ],
        [element.text(priority_to_string(todo_item.priority))],
      ),
      // Completion checkbox
      html.input([
        attribute.type_("checkbox"),
        attribute.class("todo-checkbox"),
        attribute.checked(todo_item.completed),
        event.on_check(msg.ToggleTodoComplete(todo_item.id, _)),
      ]),
      // Delete button
      html.button(
        [
          attribute.class("todo-delete-btn"),
          attribute.attribute("aria-label", "Delete todo"),
          event.on_click(msg.DeleteTodo(todo_item.id)),
        ],
        [element.text("Delete")],
      ),
      // Description (optional - only rendered if present)
      render_description(todo_item.description),
    ],
  )
}

/// Render description element only if description exists
fn render_description(desc: option.Option(String)) -> Element(Msg) {
  case desc {
    option.None -> element.text("")
    option.Some("") -> element.text("")
    option.Some(text) -> {
      case string.trim(text) {
        "" -> element.text("")
        trimmed -> html.span([attribute.class("todo-description")], [element.text(trimmed)])
      }
    }
  }
}

/// Convert Priority to lowercase string for CSS classes
fn priority_to_class(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Convert Priority to display string
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

// Import required modules
import gleam/list
