/// View functions for todo list UI

import frontend/model.{
  type Filter, type Model, All, Active, Completed, Loading, Loaded, Error,
}
import frontend/msg.{type Msg, SetFilter, RetryFetch}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo List")]),
    render_data_state(model),
  ])
}

/// Render the appropriate view based on data state
fn render_data_state(model: Model) -> Element(Msg) {
  case model.data_state {
    Loading -> render_loading()
    Error(msg) -> render_error(msg)
    Loaded -> render_loaded(model)
  }
}

/// Render loading indicator
fn render_loading() -> Element(Msg) {
  html.div([attribute.id("loading")], [
    element.text("Loading..."),
  ])
}

/// Render error state with retry button
fn render_error(error_msg: String) -> Element(Msg) {
  html.div([attribute.id("error")], [
    html.p([], [element.text("Error: " <> error_msg)]),
    html.button(
      [event.on_click(RetryFetch)],
      [element.text("Retry")]
    ),
  ])
}

/// Render the loaded state (todos or empty message)
fn render_loaded(model: Model) -> Element(Msg) {
  html.div([], [
    render_filters(model.filter),
    html.div([attribute.id("todo-list")], [
      render_todos_or_empty(model),
    ]),
  ])
}

/// Render filter buttons
fn render_filters(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    filter_button("all", All, current_filter),
    filter_button("active", Active, current_filter),
    filter_button("completed", Completed, current_filter),
  ])
}

/// Create a single filter button
fn filter_button(name: String, filter: Filter, current: Filter) -> Element(Msg) {
  let is_active = case filter == current {
    True -> "active"
    False -> ""
  }
  html.button(
    [
      attribute.class(is_active),
      attribute.attribute("data-filter", name),
      event.on_click(SetFilter(filter)),
    ],
    [element.text(name)]
  )
}

/// Render todos list or appropriate empty message
fn render_todos_or_empty(model: Model) -> Element(Msg) {
  let filtered = case model.filter {
    All -> model.todos
    Active -> list_filter(model.todos, fn(t) { !t.completed })
    Completed -> list_filter(model.todos, fn(t) { t.completed })
  }

  case filtered {
    [] -> render_empty_message(model.filter)
    todos -> render_todo_list(todos)
  }
}

/// Render empty message based on filter
fn render_empty_message(filter: Filter) -> Element(Msg) {
  let message = case filter {
    All -> "No todos yet. Add one above!"
    Active -> "No active todos. Great job!"
    Completed -> "No completed todos yet."
  }
  html.p([attribute.class("empty-message")], [element.text(message)])
}

/// Render the list of todos
fn render_todo_list(todos: List(Todo)) -> Element(Msg) {
  html.ul([], list_map(todos, render_todo_item))
}

/// Render a single todo item
fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  html.li([attribute.class(case todo_item.completed {
    True -> "completed"
    False -> "active"
  })], [
    element.text(todo_item.title),
  ])
}

/// Filter a list (helper since list.filter may have target issues)
fn list_filter(list: List(a), predicate: fn(a) -> Bool) -> List(a) {
  case list {
    [] -> []
    [head, ..tail] -> case predicate(head) {
      True -> [head, ..list_filter(tail, predicate)]
      False -> list_filter(tail, predicate)
    }
  }
}

/// Map over a list (helper)
fn list_map(list: List(a), transform: fn(a) -> b) -> List(b) {
  case list {
    [] -> []
    [head, ..tail] -> [transform(head), ..list_map(tail, transform)]
  }
}
