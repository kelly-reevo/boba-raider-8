/// View functions for todo list display
/// Renders: loading, empty, error, and populated states
/// Each todo has: data-todo-id, .todo-title, .todo-description (optional),
/// .todo-priority, .todo-checkbox, .todo-delete-btn

import frontend/model.{type ErrorInfo, type ErrorType, type Model, Network, Server, Validation}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Priority, type Todo, High, Low, Medium}

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.id("app")], [
    // Error toast container
    render_error_container(model.errors),
    // Main app content
    html.h1([], [element.text("Todo List")]),
    render_content(model),
  ])
}

/// Convert error type to string for data attribute
fn error_type_to_string(error_type: ErrorType) -> String {
  case error_type {
    Network -> "network"
    Server -> "server"
    Validation -> "validation"
  }
}

/// Get display message for error type
fn error_type_to_message(error_type: ErrorType) -> String {
  case error_type {
    Network -> "Network error. Please check your connection."
    Server -> "Server error, please try again"
    Validation -> "Validation error. Please check your input."
  }
}

/// Render a single error notification
fn render_error_notification(error: ErrorInfo) -> Element(Msg) {
  let error_message = case error.message {
    "" -> error_type_to_message(error.type_)
    msg -> msg
  }
  let type_str = error_type_to_string(error.type_)

  html.div(
    [
      attribute.class("error-notification"),
      attribute.attribute("data-error-type", type_str),
    ],
    [
      html.span([attribute.class("error-message")], [
        element.text(error_message),
      ]),
      html.button(
        [
          attribute.class("error-dismiss"),
          event.on_click(msg.DismissError(error.id)),
          attribute.attribute("aria-label", "Dismiss error"),
        ],
        [element.text("×")],
      ),
    ],
  )
}

/// Render error container with all errors
fn render_error_container(errors: List(ErrorInfo)) -> Element(Msg) {
  case errors {
    [] -> html.div([attribute.id("error-toast"), attribute.class("hidden")], [])
    _ ->
      html.div(
        [attribute.id("error-toast")],
        list.map(errors, render_error_notification),
      )
  }
}

/// Render appropriate content based on model state
fn render_content(model: Model) -> Element(Msg) {
  case model.loading {
    model.Loading -> render_loading()
    model.Error(msg) -> render_error_state(msg)
    model.Idle | model.Success -> {
      case model.todos {
        [] -> render_empty()
        _ -> render_todo_list(model)
      }
    }
  }
}

/// Loading state indicator
fn render_loading() -> Element(Msg) {
  html.div([attribute.class("loading-state")], [
    html.div([attribute.class("spinner")], []),
    element.text("Loading todos..."),
  ])
}

/// Empty state when no todos exist
fn render_empty() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [
    html.p([], [element.text("No todos yet. Add one above!")]),
  ])
}

/// Error state display (for loading errors)
fn render_error_state(error: String) -> Element(Msg) {
  html.div([attribute.class("error-state")], [
    html.p([attribute.class("error-message")], [element.text("Error: " <> error)]),
    html.button(
      [event.on_click(msg.LoadTodos), attribute.class("retry-btn")],
      [element.text("Retry")]
    ),
  ])
}

/// Render the todo list container with all todos
fn render_todo_list(model: Model) -> Element(Msg) {
  html.ul([attribute.id("todo-list")], list.map(model.todos, render_todo))
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
          attribute.title("Delete this todo"),
          event.on_click(msg.RequestDelete(todo_item.id)),
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
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
  }
}
