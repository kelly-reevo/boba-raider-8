/// View functions with error state UI

import frontend/model as model
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function
pub fn view(m: model.AppModel) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),

    // Global error container (for initial load errors)
    render_global_error(m.global_error),

    // Todo form with error container
    render_form(m),

    // List error container (for update/delete errors)
    render_list_error(m.list_error),

    // Loading state or todo list
    case m.is_loading {
      True -> render_loading()
      False -> render_todo_list(m.todos)
    },
  ])
}

/// Render global error container (#error-container)
fn render_global_error(error: model.ErrorState) -> Element(Msg) {
  case error {
    model.NoError -> html.div([attribute.attribute("data-testid", "error-container")], [])
    model.Error(message, _) ->
      html.div(
        [
          attribute.attribute("data-testid", "error-container"),
          attribute.class("error-container"),
        ],
        [
          html.div([attribute.class("error-message"), attribute.attribute("data-testid", "error-message")], [
            element.text(message),
          ]),
        ],
      )
  }
}

/// Render form error container (#form-error)
fn render_form_error(error: model.ErrorState) -> Element(Msg) {
  case error {
    model.NoError -> html.div([attribute.attribute("data-testid", "form-error")], [])
    model.Error(message, _) ->
      html.div(
        [
          attribute.attribute("data-testid", "form-error"),
          attribute.class("error-message"),
        ],
        [
          html.div([attribute.attribute("data-testid", "error-message")], [
            element.text(message),
          ]),
        ],
      )
  }
}

/// Render list error container (#list-error)
fn render_list_error(error: model.ErrorState) -> Element(Msg) {
  case error {
    model.NoError -> html.div([attribute.attribute("data-testid", "list-error")], [])
    model.Error(message, _) ->
      html.div(
        [
          attribute.attribute("data-testid", "list-error"),
          attribute.class("error-message"),
        ],
        [
          html.div([attribute.attribute("data-testid", "error-message")], [
            element.text(message),
          ]),
        ],
      )
  }
}

/// Render the todo form
fn render_form(m: model.AppModel) -> Element(Msg) {
  html.div([attribute.class("form-section")], [
    html.form(
      [
        attribute.attribute("data-testid", "todo-form"),
        event.on_submit(fn(_) { msg.FormSubmitted }),
      ],
      [
        html.input([
          attribute.attribute("data-testid", "todo-title-input"),
          attribute.type_("text"),
          attribute.value(m.form_input),
          attribute.placeholder("Add a new todo..."),
          event.on_input(msg.FormInputChanged),
        ]),
        html.button(
          [
            attribute.attribute("data-testid", "todo-submit-btn"),
            attribute.type_("submit"),
          ],
          [element.text("Add")],
        ),
      ],
    ),
    // Form error appears below the form
    render_form_error(m.form_error),
  ])
}

/// Render loading state
fn render_loading() -> Element(Msg) {
  html.div([attribute.attribute("data-testid", "todo-list-loading")], [
    element.text("Loading..."),
  ])
}

/// Render the todo list
fn render_todo_list(todos: List(model.Todo)) -> Element(Msg) {
  html.div([attribute.attribute("data-testid", "todo-list")], [
    case list.length(todos) {
      0 -> render_empty()
      _ -> render_todos(todos)
    },
  ])
}

/// Render empty state
fn render_empty() -> Element(Msg) {
  html.div([attribute.attribute("data-testid", "todo-list-empty")], [
    element.text("No todos yet. Add one above!"),
  ])
}

/// Render list of todos
fn render_todos(todos: List(model.Todo)) -> Element(Msg) {
  html.div(
    [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")],
    list.map(todos, render_todo_item),
  )
}

/// Render a single todo item
fn render_todo_item(item: model.Todo) -> Element(Msg) {
  html.div(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-testid", "todo-item"),
      attribute.attribute("data-id", item.id),
    ],
    [
      html.label([], [
        html.input([
          attribute.attribute("data-testid", "todo-checkbox"),
          attribute.type_("checkbox"),
          attribute.checked(item.completed),
          event.on_check(fn(checked) { msg.UpdateTodoRequest(item.id, checked) }),
        ]),
        html.span([attribute.attribute("data-testid", "todo-title")], [element.text(item.title)]),
      ]),
      html.button(
        [
          attribute.attribute("data-testid", "todo-delete-btn"),
          event.on_click(msg.DeleteTodoRequest(item.id)),
        ],
        [element.text("Delete")],
      ),
    ],
  )
}
