/// View rendering functions

import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main view function rendering the app
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_todo_list(model.todos),
    render_error(model.error),
  ])
}

/// Render the todo list
fn render_todo_list(items: List(Todo)) -> Element(Msg) {
  html.ul([attribute.id("todo-list")], list.map(items, render_todo_item))
}

/// Render a single todo item with toggle checkbox
fn render_todo_item(item: Todo) -> Element(Msg) {
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
      html.span([attribute.class("todo-title")], [element.text(item.title)]),
    ],
  )
}

/// Render error message
fn render_error(error: String) -> Element(Msg) {
  case error {
    "" -> html.div([attribute.id("error-message")], [])
    _ ->
      html.div(
        [attribute.id("error-message"), attribute.style("display", "block")],
        [element.text(error)],
      )
  }
}
