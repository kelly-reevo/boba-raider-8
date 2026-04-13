import frontend/model.{type Model, type FetchStatus, Idle, Loading, Success, Error}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import shared.{type Todo}

/// Render the loading indicator
fn render_loading() -> Element(Msg) {
  html.div([attribute.class("loading")], [text("Loading...")])
}

/// Render the todo list
fn render_todo_list(todos: List(Todo)) -> Element(Msg) {
  case todos {
    [] -> html.div([attribute.class("empty-state")], [text("No todos yet")])
    _ -> {
      html.ul(
        [attribute.class("todo-list")],
        list.map(todos, fn(t) {
          html.li(
            [
              attribute.class("todo-item"),
              attribute.attribute("data-todo-id", t.id),
            ],
            [text(t.title)],
          )
        }),
      )
    }
  }
}

/// Render an error message
fn render_error(message: String) -> Element(Msg) {
  html.div([attribute.class("error-message")], [text(message)])
}

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  // The list container where loading/todos/error will be rendered
  let list_content = case model.status {
    Loading -> render_loading()
    Success -> render_todo_list(model.todos)
    Error(err) -> render_error(err)
    Idle -> element.none()
  }

  html.div([attribute.class("app")], [
    html.h1([], [text("boba-raider-8")]),
    html.div([attribute.id("todo-list")], [list_content]),
  ])
}
