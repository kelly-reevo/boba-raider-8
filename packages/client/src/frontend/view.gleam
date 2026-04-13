/// View functions for rendering the todo application with empty state UI

import frontend/model as m
import frontend/model.{type Filter, type LoadingState, type Model, All, Active, Completed}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main view function rendering the complete application
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    render_header(),
    render_todo_form(model),
    render_filter_controls(model.filter),
    render_todo_list_section(model),
  ])
}

/// Render the app header
fn render_header() -> Element(Msg) {
  html.h1([], [text("boba-raider-8")])
}

/// Render the new todo form
fn render_todo_form(model: Model) -> Element(Msg) {
  html.div([attribute.id("todo-form")], [
    html.input([
      attribute.id("title-input"),
      attribute.type_("text"),
      attribute.placeholder("Title"),
      attribute.value(model.new_todo_title),
      event.on_input(msg.UpdateNewTodoTitle),
    ]),
    html.input([
      attribute.id("description-input"),
      attribute.type_("text"),
      attribute.placeholder("Description"),
      attribute.value(model.new_todo_description),
      event.on_input(msg.UpdateNewTodoDescription),
    ]),
    html.button(
      [event.on_click(msg.SubmitNewTodo)],
      [text("Add")]
    ),
  ])
}

/// Render filter control buttons
fn render_filter_controls(current_filter: Filter) -> Element(Msg) {
  html.div(
    [attribute.id("filter-controls")],
    [
      render_filter_button("all", "All", current_filter == All),
      render_filter_button("active", "Active", current_filter == Active),
      render_filter_button("completed", "Completed", current_filter == Completed),
    ]
  )
}

/// Render a single filter button
fn render_filter_button(filter_value: String, label: String, is_active: Bool) -> Element(Msg) {
  let filter = case filter_value {
    "active" -> Active
    "completed" -> Completed
    _ -> All
  }

  let base_attrs = [
    attribute.attribute("data-filter", filter_value),
    event.on_click(msg.SetFilter(filter)),
  ]

  let attrs = case is_active {
    True -> [attribute.class("active"), ..base_attrs]
    False -> base_attrs
  }

  html.button(attrs, [text(label)])
}

/// Render the todo list section including loading, empty state, and todo items
fn render_todo_list_section(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-section")], [
    render_loading_state(model.loading),
    render_todo_list_or_empty(model),
  ])
}

/// Render loading state indicator
fn render_loading_state(loading: LoadingState) -> Element(Msg) {
  case loading {
    m.Loading -> html.div([attribute.class("loading")], [text("Loading...")])
    m.Error(error) -> html.div([attribute.class("error")], [text("Error: " <> error)])
    _ -> html.div([], [])
  }
}

/// Render either the todo list or empty state based on filtered results
fn render_todo_list_or_empty(model: Model) -> Element(Msg) {
  let filtered_todos = model |> model.get_filtered_todos()

  case list.is_empty(filtered_todos) {
    True -> render_empty_state(model)
    False -> render_todo_list(filtered_todos)
  }
}

/// Render the empty state UI with context-aware message
fn render_empty_state(model: Model) -> Element(Msg) {
  let message = model |> model.get_empty_message()

  html.div(
    [
      attribute.id("empty-state"),
      attribute.style("display", "block"),
    ],
    [
      html.p([attribute.id("empty-message")], [text(message)]),
    ]
  )
}

/// Render the list of todo items
fn render_todo_list(todos: List(Todo)) -> Element(Msg) {
  html.div(
    [attribute.id("todo-list")],
    list.map(todos, render_todo_item)
  )
}

/// Render a single todo item
fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  html.div(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-id", todo_item.id),
    ],
    [
      html.input([
        attribute.class("toggle-complete"),
        attribute.type_("checkbox"),
        attribute.checked(todo_item.completed),
        event.on_check(fn(checked) { msg.ToggleTodo(todo_item.id, checked) }),
      ]),
      html.span(
        [
          attribute.class("todo-title"),
          attribute.class(case todo_item.completed {
            True -> "completed"
            False -> ""
          }),
        ],
        [text(todo_item.title)]
      ),
      html.button(
        [
          attribute.class("delete-btn"),
          event.on_click(msg.DeleteTodo(todo_item.id)),
        ],
        [text("Delete")]
      ),
    ]
  )
}
