/// View rendering with comprehensive error state display AND filter support

import frontend/model.{
  type ApiError, type FieldError, type Filter, type Model, type Todo,
  NetworkError, NotFoundError, ServerError, ValidationError, All, Active, Completed
}
import frontend/msg.{type Msg, FilterChanged, Increment, Decrement, Reset, SubmitTodo, UpdateTitle, UpdateDescription, UpdatePriority, DeleteTodo, EditTodo, RetryLoadTodos}
import gleam/int
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

    // Counter section (existing)
    html.div([attribute.class("counter")], [
      html.button([event.on_click(Decrement)], [element.text("-")]),
      html.span([attribute.class("count")], [
        element.text("Count: " <> int.to_string(model.count)),
      ]),
      html.button([event.on_click(Increment)], [element.text("+")]),
    ]),
    html.button([event.on_click(Reset), attribute.class("reset")], [
      element.text("Reset"),
    ]),

    // Boundary contract: global error container
    render_error_container("global", model.global_error),
    render_global_notification(model.global_error),

    // Todo filter section
    render_filter_section(model),
  ])
}

/// Render error container per boundary contract: showError(container, error)
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

/// Render filter section with filter buttons and todo list
fn render_filter_section(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-section")], [
    html.h2([], [element.text("Todos")]),

    // Filter buttons
    render_filter_buttons(model.current_filter),

    // Todo list with error handling
    render_todo_list(model),
  ])
}

fn render_filter_buttons(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filter-buttons")], [
    render_filter_button(All, current_filter),
    render_filter_button(Active, current_filter),
    render_filter_button(Completed, current_filter),
  ])
}

fn render_filter_button(filter: Filter, current: Filter) -> Element(Msg) {
  let label = case filter {
    All -> "All"
    Active -> "Active"
    Completed -> "Completed"
  }

  let filter_data_attr = case filter {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }

  let is_active = filter == current
  let testid = "filter-btn-" <> filter_data_attr

  html.button(
    [
      attribute.class(case is_active {
        True -> "filter-btn active"
        False -> "filter-btn"
      }),
      attribute.attribute("data-testid", testid),
      attribute.attribute("data-filter", filter_data_attr),
      event.on_click(FilterChanged(filter)),
    ],
    [element.text(label)],
  )
}

/// Render todo list with error state handling AND filter support
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
      render_todo_items(model.todos),
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
        event.on_click(RetryLoadTodos),
      ],
      [element.text("Try Again")],
    ),
  ]
}

fn render_todo_items(todos: List(Todo)) -> Element(Msg) {
  // Show empty state
  case todos {
    [] ->
      html.div(
        [
          attribute.class("todo-empty"),
          attribute.attribute("data-testid", "todo-empty"),
        ],
        [element.text("No todos found")],
      )
    items ->
      html.ul(
        [
          attribute.class("todo-list"),
          attribute.attribute("data-testid", "todo-list"),
        ],
        list.map(items, render_todo_item),
      )
  }
}

fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  html.li(
    [
      attribute.class(case todo_item.completed {
        True -> "todo-item completed"
        False -> "todo-item"
      }),
      attribute.attribute("data-testid", "todo-item-" <> todo_item.id),
      attribute.attribute("data-completed", case todo_item.completed {
        True -> "true"
        False -> "false"
      }),
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
          event.on_click(EditTodo(todo_item.id)),
        ],
        [element.text("Edit")],
      ),
      html.button(
        [
          attribute.class("delete-todo-btn"),
          attribute.attribute("data-testid", "delete-todo-btn-" <> todo_item.id),
          event.on_click(DeleteTodo(todo_item.id)),
        ],
        [element.text("Delete")],
      ),
    ],
  )
}
