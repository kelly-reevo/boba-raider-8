/// View rendering - HTML generation

import frontend/model.{type Filter, type Model, All, Active, Completed, Loading, Loaded, Idle, Submitting}
import frontend/msg.{type Msg, SetFilter, RetryFetch}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo, Low, Medium, High}

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
    model.Error(msg) -> render_error(msg)
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

/// Render the loaded state (form, filters, todos)
fn render_loaded(model: Model) -> Element(Msg) {
  html.div([], [
    render_form(model),
    render_error_display(model),
    render_filters(model.filter),
    html.div([attribute.id("todo-list")], [
      render_todos_or_empty(model),
    ]),
  ])
}

/// Render the todo creation form
fn render_form(model: Model) -> Element(Msg) {
  html.form(
    [
      attribute.id("todo-form"),
      attribute.attribute("onsubmit", "event.preventDefault(); return false;"),
    ],
    [
      // Title input
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-title")], [element.text("Title")]),
        html.input([
          attribute.id("todo-title"),
          attribute.type_("text"),
          attribute.value(model.form.title),
          event.on_input(msg.TitleChanged),
        ]),
      ]),

      // Description textarea
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-description")], [element.text("Description")]),
        html.textarea(
          [
            attribute.id("todo-description"),
            attribute.value(model.form.description),
            event.on_input(msg.DescriptionChanged),
          ],
          "",
        ),
      ]),

      // Priority select
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-priority")], [element.text("Priority")]),
        html.select(
          [
            attribute.id("todo-priority"),
            event.on_input(fn(value) {
              case value {
                "low" -> msg.PriorityChanged(Low)
                "medium" -> msg.PriorityChanged(Medium)
                "high" -> msg.PriorityChanged(High)
                _ -> msg.PriorityChanged(Medium)
              }
            }),
          ],
          [
            html.option(
              [attribute.value("low"), attribute.selected(model.form.priority == Low)],
              "Low",
            ),
            html.option(
              [attribute.value("medium"), attribute.selected(model.form.priority == Medium)],
              "Medium",
            ),
            html.option(
              [attribute.value("high"), attribute.selected(model.form.priority == High)],
              "High",
            ),
          ],
        ),
      ]),

      // Submit button
      html.button(
        [
          attribute.type_("button"),
          attribute.disabled(model.submit_state == Submitting),
          event.on_click(msg.SubmitForm),
        ],
        case model.submit_state {
          Submitting -> [element.text("Adding...")]
          _ -> [element.text("Add")]
        },
      ),
    ],
  )
}

/// Render error display area for form submission
fn render_error_display(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.id("error-display"),
      attribute.class(case string.is_empty(model.error) {
        True -> "error-display hidden"
        False -> "error-display"
      }),
    ],
    case string.is_empty(model.error) {
      True -> []
      False -> [element.text(model.error)]
    },
  )
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
    Active -> list.filter(model.todos, fn(t) { !t.completed })
    Completed -> list.filter(model.todos, fn(t) { t.completed })
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
  html.ul([], list.map(todos, render_todo_item))
}

/// Render a single todo item
fn render_todo_item(item: Todo) -> Element(Msg) {
  let priority_class = priority_class_from_string(item.priority)

  html.li(
    [
      attribute.data("id", item.id),
      attribute.class(case item.completed {
        True -> "completed"
        False -> ""
      }),
    ],
    [
      html.span([attribute.class("title")], [element.text(item.title)]),
      html.span(
        [attribute.class("priority " <> priority_class)],
        [element.text(item.priority)],
      ),
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
      ]),
      html.button([attribute.class("delete")], [element.text("Delete")]),
    ],
  )
}

/// Get CSS class from priority string
fn priority_class_from_string(priority: String) -> String {
  case priority {
    "low" -> "priority-low"
    "medium" -> "priority-medium"
    "high" -> "priority-high"
    _ -> "priority-medium"
  }
}
