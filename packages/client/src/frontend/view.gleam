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
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Priority, type Todo, Low, Medium, High}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Error message container (per boundary contract: <div id='error-message'>)
    render_error_container(model),

    // Header
    html.h1([], [element.text("Todo List")]),

    // Add todo form
    render_form(model),

    // Filter tabs
    render_filters(model.filter),

    // Todo list
    render_todo_list(model),
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
    msg -> html.span([attribute.class("field-error")], [element.text(msg)])
  }
}

/// Render filter tabs
fn render_filters(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    render_filter_button("All", All, current_filter),
    render_filter_button("Active", Active, current_filter),
    render_filter_button("Completed", Completed, current_filter),
  ])
}

fn render_filter_button(label: String, filter: Filter, current: Filter) -> Element(Msg) {
  let is_active = filter == current
  html.button(
    [
      attribute.class(case is_active {
        True -> "filter-button active"
        False -> "filter-button"
      }),
      event.on_click(msg.FilterChanged(filter)),
    ],
    [element.text(label)],
  )
}

/// Render the todo list with loading, empty, and populated states
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-list")], [
    case model.loading {
      Loading -> html.p([attribute.class("loading-message")], [element.text("Loading todos...")])
      _ -> {
        let filtered = filter_todos(model.todos, model.filter)
        case filtered {
          [] -> {
            case model.filter {
              All -> html.p([attribute.class("empty-message")], [element.text("No todos yet. Add one above!")])
              Active -> html.p([attribute.class("empty-message")], [element.text("No active todos.")])
              Completed -> html.p([attribute.class("empty-message")], [element.text("No completed todos.")])
            }
          }
          todos -> html.div([], list.map(todos, render_todo_item))
        }
      }
    },
  ])
}

fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  html.div([attribute.class("todo-item"), attribute.id("todo-" <> todo_item.id)], [
    html.input([
      attribute.type_("checkbox"),
      attribute.class("todo-checkbox"),
      attribute.checked(todo_item.completed),
      event.on_check(fn(checked) { msg.ToggleTodo(todo_item.id, checked) }),
    ]),
    html.span(
      [
        attribute.class(case todo_item.completed {
          True -> "todo-title completed"
          False -> "todo-title"
        }),
      ],
      [element.text(todo_item.title)],
    ),
    html.span([attribute.class("todo-priority priority-" <> priority_to_string(todo_item.priority))], [
      element.text(priority_to_string(todo_item.priority)),
    ]),
    html.button(
      [attribute.class("delete-button"), event.on_click(msg.DeleteTodo(todo_item.id))],
      [element.text("Delete")],
    ),
  ])
}

fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

fn filter_todos(todos: List(Todo), filter: Filter) -> List(Todo) {
  case filter {
    All -> todos
    Active -> filter_by_completed(todos, False)
    Completed -> filter_by_completed(todos, True)
  }
}

fn filter_by_completed(todos: List(Todo), completed: Bool) -> List(Todo) {
  case todos {
    [] -> []
    [first, ..rest] -> {
      case first.completed == completed {
        True -> [first, ..filter_by_completed(rest, completed)]
        False -> filter_by_completed(rest, completed)
      }
    }
  }
}
