/// View rendering with comprehensive error state display

import frontend/model.{type ApiError, type FieldError, type Model, type Todo, NetworkError, NotFoundError, ServerError, ValidationError}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    // Boundary contract: global error container
    render_error_container("global", model.global_error),
    render_global_notification(model.global_error),
    render_todo_form(model),
    render_todo_list(model),
  ])
}

/// Render error container per boundary contract: showError(container, error)
/// Container can be 'form', 'list', or 'global'
fn render_error_container(container: String, error: Option(ApiError)) -> Element(Msg) {
  html.div(
    [
      attribute.class("error-container-" <> container),
      attribute.attribute("data-testid", "error-container-" <> container),
      case error {
        None -> attribute.styles([#("display", "none")])
        Some(_) -> attribute.styles([#("display", "block")])
      },
    ],
    case error {
      None -> []
      Some(e) -> {
        let msg_text = case e {
          NotFoundError(msg) -> msg
          ServerError(msg) -> msg
          NetworkError(msg) -> msg
          ValidationError(_) -> ""
        }
        case string.is_empty(msg_text) {
          True -> []
          False -> [
            html.div(
              [
                attribute.class("error-message-" <> container),
                attribute.attribute("data-testid", "error-message-" <> container),
                attribute.attribute("role", case container {
                  "global" -> "alert"
                  _ -> ""
                }),
              ],
              [element.text(msg_text)],
            ),
          ]
        }
      }
    },
  )
}

/// Render global notification area for non-field errors
fn render_global_notification(error: Option(ApiError)) -> Element(Msg) {
  let content = case error {
    None -> []
    Some(e) -> {
      let msg_text = case e {
        NotFoundError(msg) -> msg
        ServerError(msg) -> msg
        NetworkError(msg) -> msg
        ValidationError(_) -> ""
      }
      case string.is_empty(msg_text) {
        True -> []
        False -> [element.text(msg_text)]
      }
    }
  }

  html.div(
    [
      attribute.class("global-notification"),
      attribute.attribute("data-testid", "global-notification"),
      attribute.attribute("role", "alert"),
      case error {
        None -> attribute.styles([#("display", "none")])
        Some(_) -> attribute.styles([#("display", "block")])
      },
      case error {
        Some(NotFoundError(_)) | Some(ServerError(_)) | Some(NetworkError(_)) ->
          attribute.class("error")
        _ -> attribute.class("")
      },
    ],
    content,
  )
}

/// Render todo form with field-level error display
fn render_todo_form(model: Model) -> Element(Msg) {
  let title_error = get_field_error(model.form_errors, "title")
  let desc_error = get_field_error(model.form_errors, "description")
  let priority_error = get_field_error(model.form_errors, "priority")

  html.div(
    [
      attribute.class("todo-form-container"),
      attribute.attribute("data-testid", "todo-form-container"),
      attribute.attribute("data-error", case model.global_error {
        Some(NetworkError(msg)) -> msg
        _ -> ""
      }),
    ],
    [
      // Boundary contract: form error container
      render_error_container("form", case model.global_error {
        Some(NetworkError(_)) -> None
        other -> other
      }),
      html.form(
        [
          attribute.class("todo-form"),
          attribute.attribute("data-testid", "todo-form"),
          event.on_submit(fn(_form_data) { msg.SubmitTodo }),
        ],
        [
          html.div([attribute.class("form-group")], [
            html.input([
              attribute.type_("text"),
              attribute.name("title"),
              attribute.value(model.form_title),
              attribute.placeholder("Title"),
              attribute.attribute("data-testid", "todo-title-input"),
              event.on_input(msg.UpdateTitle),
            ]),
            render_field_error(title_error, "title"),
          ]),
          html.div([attribute.class("form-group")], [
            html.input([
              attribute.type_("text"),
              attribute.name("description"),
              attribute.value(model.form_description),
              attribute.placeholder("Description"),
              attribute.attribute("data-testid", "todo-description-input"),
              event.on_input(msg.UpdateDescription),
            ]),
            render_field_error(desc_error, "description"),
          ]),
          html.div([attribute.class("form-group")], [
            html.select(
              [
                attribute.name("priority"),
                attribute.value(model.form_priority),
                attribute.attribute("data-testid", "todo-priority-input"),
                event.on_input(msg.UpdatePriority),
              ],
              [
                html.option([attribute.value("low")], "Low"),
                html.option([attribute.value("medium")], "Medium"),
                html.option([attribute.value("high")], "High"),
              ],
            ),
            render_field_error(priority_error, "priority"),
          ]),
          html.button(
            [
              attribute.type_("submit"),
              attribute.attribute("data-testid", "todo-submit-btn"),
            ],
            [element.text("Add Todo")],
          ),
        ],
      ),
    ],
  )
}

/// Render field-specific error message
fn render_field_error(error: Option(String), field: String) -> Element(Msg) {
  let has_error = case error {
    None -> False
    Some(msg) -> !string.is_empty(msg)
  }

  let content = case error {
    None -> ""
    Some(msg) -> msg
  }

  html.div(
    [
      attribute.class("error-field"),
      attribute.attribute("data-testid", "error-field-" <> field),
      case has_error {
        True -> attribute.styles([#("display", "block")])
        False -> attribute.styles([#("display", "none")])
      },
      attribute.attribute("data-field", field),
    ],
    [element.text(content)],
  )
}

/// Get error message for a specific field
fn get_field_error(errors: List(FieldError), field: String) -> Option(String) {
  case list.find(errors, fn(e) { e.field == field }) {
    Ok(e) -> Some(e.message)
    Error(_) -> None
  }
}

/// Render todo list with error state handling
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class("todo-list-container"),
      attribute.attribute("data-testid", "todo-list-container"),
    ],
    [
      // Boundary contract: list error container
      render_error_container("list", model.list_error),
      html.div(
        [
          attribute.class("list-error-container"),
          attribute.attribute("data-testid", "list-error-container"),
          case model.list_error {
            None -> attribute.styles([#("display", "none")])
            Some(_) -> attribute.styles([#("display", "block")])
          },
        ],
        case model.list_error {
          None -> []
          Some(error) -> render_list_error_content(error)
        },
      ),
      html.div(
        [
          attribute.class("loading-spinner"),
          attribute.attribute("data-testid", "loading-spinner"),
          case model.loading {
            True -> attribute.styles([#("display", "block")])
            False -> attribute.styles([#("display", "none")])
          },
        ],
        [element.text("Loading...")],
      ),
      html.ul(
        [
          attribute.class("todo-list"),
          attribute.attribute("data-testid", "todo-list"),
        ],
        list.map(model.todos, render_todo_item),
      ),
    ],
  )
}

/// Render list error content with retry button
fn render_list_error_content(error: ApiError) -> List(Element(Msg)) {
  let message = case error {
    ServerError(msg) -> msg
    NetworkError(msg) -> msg
    _ -> "Failed to load todos"
  }

  [
    html.div(
      [
        attribute.class("error-message-text"),
        attribute.attribute("data-testid", "error-message-text"),
      ],
      [element.text(message)],
    ),
    html.button(
      [
        attribute.class("retry-load-btn"),
        attribute.attribute("data-testid", "retry-load-btn"),
        event.on_click(msg.RetryLoadTodos),
      ],
      [element.text("Try Again")],
    ),
  ]
}

/// Render a single todo item
fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  html.li(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-testid", "todo-item-" <> todo_item.id),
    ],
    [
      html.span(
        [
          attribute.class("todo-title"),
          attribute.attribute("data-testid", "todo-title-" <> todo_item.id),
        ],
        [element.text(todo_item.title)],
      ),
      html.button(
        [
          attribute.class("edit-todo-btn"),
          attribute.attribute("data-testid", "edit-todo-btn-" <> todo_item.id),
          event.on_click(msg.EditTodo(todo_item.id)),
        ],
        [element.text("Edit")],
      ),
      html.button(
        [
          attribute.class("delete-todo-btn"),
          attribute.attribute("data-testid", "delete-todo-btn-" <> todo_item.id),
          event.on_click(msg.DeleteTodo(todo_item.id)),
        ],
        [element.text("Delete")],
      ),
    ],
  )
}
