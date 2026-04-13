/// View rendering - HTML generation

import frontend/model.{type Filter, type Model, All, Active, Completed, Loading, Loaded, Idle, Submitting}
import frontend/msg.{type Msg, SetFilter, RetryFetch, DismissError, ToggleTodo}
import gleam/list
import gleam/option.{type Option, Some}
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
    model.Error(msg) -> render_error_state(msg)
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
fn render_error_state(error_msg: String) -> Element(Msg) {
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
    render_delete_error(model),
    render_filter_tabs(model.filter),
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
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-title")], [element.text("Title")]),
        html.input([
          attribute.id("todo-title"),
          attribute.type_("text"),
          attribute.value(model.form.title),
          event.on_input(msg.TitleChanged),
        ]),
      ]),

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

/// Render delete error banner
fn render_delete_error(model: Model) -> Element(Msg) {
  case model.submit_state {
    model.Error(message) -> {
      html.div([attribute.class("error-banner")], [
        element.text(message),
        html.button([event.on_click(DismissError), attribute.class("dismiss")], [
          element.text("Dismiss"),
        ]),
      ])
    }
    _ -> html.div([], [])
  }
}

/// Render filter tabs
fn render_filter_tabs(active_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filter-tabs")], [
    filter_tab_button("all", "All", active_filter == All),
    filter_tab_button("active", "Active", active_filter == Active),
    filter_tab_button("completed", "Completed", active_filter == Completed),
  ])
}

/// Create a single filter tab button
fn filter_tab_button(filter: String, label: String, is_active: Bool) -> Element(Msg) {
  let attrs = case is_active {
    True -> [
      attribute.class("filter-tab active"),
      attribute.attribute("data-filter", filter),
      event.on_click(case filter {
        "active" -> SetFilter(Active)
        "completed" -> SetFilter(Completed)
        _ -> SetFilter(All)
      }),
    ]
    False -> [
      attribute.class("filter-tab"),
      attribute.attribute("data-filter", filter),
      event.on_click(case filter {
        "active" -> SetFilter(Active)
        "completed" -> SetFilter(Completed)
        _ -> SetFilter(All)
      }),
    ]
  }
  html.button(attrs, [element.text(label)])
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
    todos -> render_todo_list(todos, model.deleting_id)
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
fn render_todo_list(todos: List(Todo), deleting_id: Option(String)) -> Element(Msg) {
  html.ul([attribute.class("todo-list")], list.map(todos, fn(item) {
    render_todo_item(item, deleting_id)
  }))
}

/// Render a single todo item
fn render_todo_item(item: Todo, deleting_id: Option(String)) -> Element(Msg) {
  let is_deleting = case deleting_id {
    Some(id) if id == item.id -> True
    _ -> False
  }

  let priority_class = priority_class_from_string(item.priority)
  let completed_class = case item.completed {
    True -> "todo-title completed"
    False -> "todo-title"
  }

  html.li(
    [
      attribute.data("id", item.id),
      attribute.class("todo-item"),
      attribute.class(case is_deleting {
        True -> "deleting"
        False -> ""
      }),
      attribute.class(case item.completed {
        True -> "completed"
        False -> ""
      }),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.class("todo-checkbox"),
        attribute.checked(item.completed),
        event.on_check(fn(checked) { ToggleTodo(item.id, checked) }),
      ]),
      html.span([attribute.class(completed_class)], [element.text(item.title)]),
      html.span(
        [attribute.class("priority " <> priority_class)],
        [element.text(item.priority)],
      ),
      html.button(
        [
          event.on_click(msg.DeleteTodo(item.id)),
          attribute.class("delete-btn"),
          attribute.disabled(is_deleting),
          attribute.attribute("data-todo-id", item.id),
        ],
        [
          element.text(case is_deleting {
            True -> "Deleting..."
            False -> "Delete"
          }),
        ]
      ),
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
