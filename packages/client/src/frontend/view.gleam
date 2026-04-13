import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

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
      [attribute.id("error-container"), attribute.class("error")],
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
  html.li(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-id", item.id),
    ],
    [
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
