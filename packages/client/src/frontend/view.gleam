/// Main application view

import frontend/model.{type Model, Idle, Loading, Error, Success}
import frontend/msg.{type Msg, LoadTodos}
import frontend/todo_view
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [text("boba-raider-8")]),

    // Counter section (legacy)
    html.div([attribute.class("counter")], [
      html.button([event.on_click(msg.Decrement)], [text("-")]),
      html.span([attribute.class("count")], [
        text("Count: " <> int.to_string(model.count)),
      ]),
      html.button([event.on_click(msg.Increment)], [text("+")]),
    ]),
    html.button([event.on_click(msg.Reset), attribute.class("reset")], [
      text("Reset"),
    ]),

    // Todo list section
    html.h2([], [text("Todo List")]),
    html.button([event.on_click(LoadTodos)], [text("Load Todos")]),

    // Render based on loading state
    render_todo_section(model),
  ])
}

/// Render the todo section based on loading state
fn render_todo_section(model: Model) -> Element(Msg) {
  case model.loading_state {
    Idle -> html.p([], [text("Click 'Load Todos' to fetch items")])
    Loading -> html.p([attribute.class("loading")], [text("Loading...")])
    model.Error(err) -> html.p([attribute.class("error")], [text("Error: " <> err)])
    Success -> {
      case list.is_empty(model.todos) {
        True -> html.p([attribute.class("empty")], [text("No todos found")])
        False -> todo_view.todo_list(model.todos)
      }
    }
  }
}
