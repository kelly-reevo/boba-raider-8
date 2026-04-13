import frontend/model.{type Model, type Todo, type LoadingState, Error}
import frontend/msg.{type Msg, DeleteTodo, DismissError}
import gleam/list
import gleam/option.{type Option, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function - renders the entire application
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo List")]),
    render_error(model.loading_state),
    render_todo_list(model.todos, model.deleting_id),
  ])
}

/// Render error message if present
fn render_error(state: LoadingState) -> Element(Msg) {
  case state {
    Error(message) -> {
      html.div([attribute.class("error-banner")], [
        element.text(message),
        html.button([event.on_click(DismissError), attribute.class("dismiss")], [
          element.text("Dismiss"),
        ]),
      ])
    }
    _ -> html.div([], [])
  }
}

/// Render the todo list with all states
fn render_todo_list(todos: List(Todo), deleting_id: Option(String)) -> Element(Msg) {
  case todos {
    // Empty state
    [] -> {
      html.div([attribute.class("empty-state")], [
        html.p([], [element.text("No todos yet. Add one to get started!")]),
      ])
    }

    // Populated list
    _ -> {
      html.ul([attribute.class("todo-list")], list.map(todos, fn(item) {
        render_todo_item(item, deleting_id)
      }))
    }
  }
}

/// Render a single todo item with delete button
fn render_todo_item(item: Todo, deleting_id: Option(String)) -> Element(Msg) {
  let is_deleting = case deleting_id {
    Some(id) if id == item.id -> True
    _ -> False
  }

  html.li(
    [
      attribute.class("todo-item"),
      attribute.class(case is_deleting {
        True -> "deleting"
        False -> ""
      }),
      attribute.id("todo-" <> item.id),
    ],
    [
      html.div([attribute.class("todo-content")], [
        html.span([attribute.class("todo-title")], [element.text(item.title)]),
        html.span([attribute.class("todo-priority")], [element.text(item.priority)]),
      ]),
      html.button(
        [
          event.on_click(DeleteTodo(item.id)),
          attribute.class("delete-btn"),
          attribute.disabled(is_deleting),
          attribute.attribute("data-todo-id", item.id),
        ],
        [
          element.text(case is_deleting {
            True -> "Deleting..."
            False -> "Delete"
          }),
        ]
      ),
    ]
  )
}
