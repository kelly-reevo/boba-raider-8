/// View rendering functions

import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main view function rendering the app
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    error_view(model.error),
    todo_list_view(model.todos),
  ])
}

fn error_view(error: String) -> Element(Msg) {
  case string.is_empty(error) {
    True -> html.div([], [])
    False -> html.div(
      [attribute.id("error-message"), attribute.class("error"), attribute.style("display", "block")],
      [element.text(error)],
    )
  }
}

fn todo_list_view(todos: List(Todo)) -> Element(Msg) {
  case list.is_empty(todos) {
    True -> html.div([attribute.class("empty-state")], [
      element.text("No items yet. Add one above!"),
    ])
    False -> html.ul(
      [attribute.id("todo-list")],
      list.map(todos, todo_item_view),
    )
  }
}

fn todo_item_view(item: Todo) -> Element(Msg) {
  let completed_class = case item.completed {
    True -> "todo-item completed"
    False -> "todo-item"
  }

  let data_completed = case item.completed {
    True -> "true"
    False -> "false"
  }

  html.li(
    [
      attribute.class(completed_class),
      attribute.attribute("data-id", item.id),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.class("toggle"),
        attribute.checked(item.completed),
        attribute.attribute("data-completed", data_completed),
        event.on_check(fn(checked) { msg.ToggleTodo(item.id, checked) }),
      ]),
      html.span([attribute.class("title")], [element.text(item.title)]),
      html.button(
        [
          attribute.class("delete"),
          attribute.attribute("data-id", item.id),
          event.on_click(msg.DeleteTodo(item.id)),
        ],
        [element.text("Delete")],
      ),
    ],
  )
}
