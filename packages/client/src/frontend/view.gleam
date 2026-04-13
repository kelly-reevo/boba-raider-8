import frontend/model.{
  type ErrorState, type Filter, type FormState, type LoadingState, type Model,
  All, Active, Completed, Idle, Loading, Saving, Deleting, is_retryable, get_field_error,
}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared.{type Priority, type Todo, Low, Medium, High}

/// Main view function rendering the complete application
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Error message container (per boundary contract: <div id='error-message'>)
    render_error_container(model),

    // Header
    html.h1([], [element.text("Todo List")]),

    // Add todo form
    render_form(model),

    // Filter tabs with data-filter attributes per boundary contract
    render_filters(model.filter),

    // Todo list with empty state support
    render_todo_list_section(model),
  ])
}

/// Render error container per boundary contract:
/// - <div id='error-message'> for global errors
/// - Network errors: user-friendly message with retry button
/// - Validation errors: no retry button
fn render_error_container(model: Model) -> Element(Msg) {
  case model.error {
    None -> {
      // Empty error container (required for DOM structure tests)
      html.div([attribute.id("error-message"), attribute.class("error-container empty")], [])
    }
    Some(error) -> {
      let children = case model.loading {
        Loading -> []
        _ -> {
          let message_el = html.p([attribute.class("error-message-text")], [
            element.text(error.message),
          ])
          let retry_button = case is_retryable(error), model.retry_action {
            True, Some(_) -> [
              html.button(
                [
                  attribute.class("retry-button"),
                  event.on_click(msg.RetryAction),
                ],
                [element.text("Retry")],
              ),
            ]
            _, _ -> []
          }
          [message_el, ..retry_button]
        }
      }

      html.div(
        [
          attribute.id("error-message"),
          attribute.class("error-container"),
        ],
        children,
      )
    }
  }
}

/// Render the add todo form with field-specific validation errors
fn render_form(model: Model) -> Element(Msg) {
  let title_error = get_field_error(model, "title")
  let description_error = get_field_error(model, "description")
  let priority_error = get_field_error(model, "priority")

  html.div([attribute.class("todo-form")], [
    // Title field with error
    html.div([attribute.class("form-field")], [
      html.label([attribute.for("title-input")], [element.text("Title")]),
      html.input([
        attribute.id("title-input"),
        attribute.type_("text"),
        attribute.value(model.form.title),
        attribute.placeholder("Enter todo title..."),
        event.on_input(msg.FormTitleChanged),
        attribute.class(case title_error {
          "" -> ""
          _ -> "error"
        }),
      ]),
      render_field_error(title_error),
    ]),

    // Description field with error
    html.div([attribute.class("form-field")], [
      html.label([attribute.for("description-input")], [element.text("Description")]),
      html.input([
        attribute.id("description-input"),
        attribute.type_("text"),
        attribute.value(model.form.description),
        attribute.placeholder("Enter description (optional)..."),
        event.on_input(msg.FormDescriptionChanged),
        attribute.class(case description_error {
          "" -> ""
          _ -> "error"
        }),
      ]),
      render_field_error(description_error),
    ]),

    // Priority field with error
    html.div([attribute.class("form-field")], [
      html.label([attribute.for("priority-input")], [element.text("Priority")]),
      html.select(
        [
          attribute.id("priority-input"),
          event.on_input(fn(val) {
            msg.FormPriorityChanged(case val {
              "high" -> High
              "low" -> Low
              _ -> Medium
            })
          }),
          attribute.class(case priority_error {
            "" -> ""
            _ -> "error"
          }),
        ],
        case model.form.priority {
          Low -> [
            html.option([attribute.value("low"), attribute.selected(True)], "Low"),
            html.option([attribute.value("medium")], "Medium"),
            html.option([attribute.value("high")], "High"),
          ]
          Medium -> [
            html.option([attribute.value("low")], "Low"),
            html.option([attribute.value("medium"), attribute.selected(True)], "Medium"),
            html.option([attribute.value("high")], "High"),
          ]
          High -> [
            html.option([attribute.value("low")], "Low"),
            html.option([attribute.value("medium")], "Medium"),
            html.option([attribute.value("high"), attribute.selected(True)], "High"),
          ]
        },
      ),
      render_field_error(priority_error),
    ]),

    // Submit button
    html.button(
      [
        attribute.class("submit-button"),
        event.on_click(msg.FormSubmit),
        attribute.disabled(model.loading == Saving),
      ],
      case model.loading {
        Saving -> [element.text("Adding...")]
        _ -> [element.text("Add Todo")]
      },
    ),
  ])
}

/// Render field-specific error message
fn render_field_error(error_msg: String) -> Element(Msg) {
  case error_msg {
    "" -> html.span([attribute.class("field-error empty")], [])
    _ -> html.span([attribute.class("field-error")], [element.text(error_msg)])
  }
}

/// Render filter tabs per boundary contract:
/// - data-filter attributes: "all", "active", "completed"
/// - "active" CSS class on active filter button
fn render_filters(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.id("filter-controls")], [
    render_filter_button("all", "All", current_filter),
    render_filter_button("active", "Active", current_filter),
    render_filter_button("completed", "Completed", current_filter),
  ])
}

fn render_filter_button(filter_value: String, label: String, current_filter: Filter) -> Element(Msg) {
  let filter = case filter_value {
    "active" -> Active
    "completed" -> Completed
    _ -> All
  }

  let is_active = filter == current_filter

  let base_attrs = [
    attribute.attribute("data-filter", filter_value),
    event.on_click(msg.FilterChanged(filter)),
  ]

  let attrs = case is_active {
    True -> [attribute.class("active"), ..base_attrs]
    False -> base_attrs
  }

  html.button(attrs, [element.text(label)])
}

/// Render the todo list section including loading state, empty state, and todo items
fn render_todo_list_section(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-section")], [
    render_loading_state(model.loading),
    render_todo_list_or_empty(model),
  ])
}

/// Render loading state indicator
fn render_loading_state(loading: LoadingState) -> Element(Msg) {
  case loading {
    Loading -> html.div([attribute.id("loading-state")], [element.text("Loading todos...")])
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

/// Render the empty state UI with context-aware message per boundary contract:
/// - All filter: "No todos yet. Add your first todo above!"
/// - Active filter: "No active todos"
/// - Completed filter: "No completed todos"
fn render_empty_state(model: Model) -> Element(Msg) {
  let message = model |> model.get_empty_message()

  html.div(
    [
      attribute.id("empty-state"),
      attribute.style("display", "block"),
    ],
    [
      html.p([attribute.id("empty-message")], [element.text(message)]),
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
        [element.text(todo_item.title)]
      ),
      html.button(
        [
          attribute.class("delete-btn"),
          event.on_click(msg.DeleteTodo(todo_item.id)),
        ],
        [element.text("Delete")]
      ),
    ]
  )
}
