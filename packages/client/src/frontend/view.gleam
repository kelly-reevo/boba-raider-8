/// View rendering for the application

import frontend/model.{type Model}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo, High, Low, Medium}
import gleam/list

/// Main view function - renders the entire application
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo List")]),
    render_content(model),
  ])
}

/// Render appropriate content based on model state
fn render_content(m: Model) -> Element(Msg) {
  case m.loading_state {
    model.Loading -> render_loading()
    model.Error(msg) -> render_error(msg)
    model.Idle -> {
      case model.is_empty(m) {
        True -> render_empty()
        False -> render_todo_list(m)
      }
    }
  }
}

/// Loading state - shows spinner while data loads
fn render_loading() -> Element(Msg) {
  html.div([attribute.class("loading-state")], [
    html.div([attribute.class("spinner")], []),
    element.text("Loading..."),
  ])
}

/// Empty state - shown when no todos exist
fn render_empty() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [
    html.p([], [element.text("No todos yet. Create your first todo to get started!")]),
  ])
}

/// Error state - shown when API calls fail
fn render_error(message: String) -> Element(Msg) {
  html.div([attribute.class("error-state")], [
    html.p([attribute.class("error-message")], [element.text("Error: " <> message)]),
    html.button(
      [event.on_click(msg.LoadTodos), attribute.class("retry-btn")],
      [element.text("Retry")]
    ),
  ])
}

/// Populated state - renders the list of todos
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-list")], [
    html.ul([attribute.class("todos")], list.map(model.todos, render_todo_item)),
  ])
}

/// Render a single todo item with delete button
fn render_todo_item(item: Todo) -> Element(Msg) {
  let priority_class = case item.priority {
    Low -> "priority-low"
    Medium -> "priority-medium"
    High -> "priority-high"
  }

  let completed_class = case item.completed {
    True -> "completed"
    False -> ""
  }

  html.li(
    [
      attribute.class("todo-item " <> priority_class <> " " <> completed_class),
      attribute.attribute("data-todo-id", item.id),
    ],
    [
      html.div([attribute.class("todo-content")], [
        html.span([attribute.class("todo-title")], [element.text(item.title)]),
        html.span([attribute.class("todo-priority-badge")], [
          element.text(priority_to_string(item.priority)),
        ]),
      ]),
      html.button(
        [
          event.on_click(msg.RequestDelete(item.id)),
          attribute.class("todo-delete-btn"),
          attribute.title("Delete this todo"),
        ],
        [element.text("Delete")]
      ),
    ]
  )
}

/// Convert priority to display string
fn priority_to_string(priority: shared.Priority) -> String {
  case priority {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
  }
}
