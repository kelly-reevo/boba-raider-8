import gleam/int
import gleam/list
import gleam/option.{None, Some}
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo List")]),

    // Error notification
    case model.error {
      "" -> element.none()
      error -> html.div([attribute.class("error-notification")], [
        element.text(error),
      ])
    },

    // Todo list with all states
    view_todo_list(model),

    // Counter demo (legacy)
    html.div([attribute.class("counter-demo")], [
      html.h2([], [element.text("Counter Demo")]),
      html.div([attribute.class("counter")], [
        html.button([event.on_click(msg.Decrement)], [element.text("-")]),
        html.span([attribute.class("count")], [
          element.text("Count: " <> int.to_string(model.count)),
        ]),
        html.button([event.on_click(msg.Increment)], [element.text("+")]),
      ]),
      html.button([event.on_click(msg.Reset), attribute.class("reset")], [
        element.text("Reset"),
      ]),
    ]),
  ])
}

/// Render todo list with loading, empty, error, and populated states
fn view_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-list-container")], [
    html.h2([], [element.text("Todos")]),

    // Loading state
    case model.deleting_id {
      Some(_) -> html.div([attribute.class("loading")], [
        element.text("Deleting..."),
      ])
      None -> element.none()
    },

    // Empty state
    case model.todos {
      [] -> html.div([attribute.class("empty-state")], [
        html.p([], [element.text("No todos yet. Add one above!")]),
      ])

      // Populated state
      todos -> html.ul([attribute.class("todo-list")], list.map(todos, view_todo_item(model)))
    },
  ])
}

/// Render a single todo item with delete button
fn view_todo_item(model: Model) -> fn(Todo) -> Element(Msg) {
  fn(item: Todo) {
    let is_deleting = case model.deleting_id {
      Some(id) if id == item.id -> True
      _ -> False
    }

    html.li(
      [
        attribute.class("todo-item"),
        attribute.data("id", item.id),
        attribute.class(case is_deleting {
          True -> "todo-item deleting"
          False -> "todo-item"
        }),
      ],
      [
        // Todo content
        html.div([attribute.class("todo-content")], [
          html.span([attribute.class("todo-title")], [element.text(item.title)]),
        ]),

        // Delete button with click handler
        html.button(
          [
            attribute.class("delete-btn"),
            event.on_click(msg.DeleteTodoClick(item.id)),
            attribute.disabled(is_deleting),
          ],
          [element.text(case is_deleting {
            True -> "Deleting..."
            False -> "Delete"
          })],
        ),
      ]
    )
  }
}
