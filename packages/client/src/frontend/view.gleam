import gleam/list
import frontend/model.{type Model}
import frontend/msg.{type Msg, ToggleTodo}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_todo_list(model.todos),
    render_error(model.error),
  ])
}

fn render_todo_list(todos: List(Todo)) -> Element(Msg) {
  html.ul([attribute.id("todo-list")], list.map(todos, render_todo_item))
}

fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  let completed_class = case todo_item.completed {
    True -> "todo-title completed"
    False -> "todo-title"
  }

  html.li([attribute.class("todo-item"), attribute.data("id", todo_item.id)], [
    html.input([
      attribute.type_("checkbox"),
      attribute.class("todo-checkbox"),
      attribute.checked(todo_item.completed),
      event.on_check(fn(checked) { ToggleTodo(todo_item.id, checked) }),
    ]),
    html.span([attribute.class(completed_class)], [element.text(todo_item.title)]),
  ])
}

fn render_error(error: String) -> Element(Msg) {
  case error {
    "" -> html.div([], [])
    message -> html.div([attribute.class("error-message")], [element.text(message)])
  }
}
