/// Application view with loading states and disabled interactive elements

import frontend/model.{type Model, is_creating, is_deleting, is_list_loading, is_updating}
import frontend/msg.{type Msg, ClearError, DeleteTodo, LoadTodos, SubmitForm, ToggleTodo, UpdateDescription, UpdateTitle}
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared.{type Todo, High, Low, Medium}

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [text("Todo App")]),
    error_view(model),
    form_view(model),
    todo_list_view(model),
  ])
}

/// Error message display
fn error_view(model: Model) -> Element(Msg) {
  case model.error {
    None -> html.div([], [])
    Some(error_msg) -> {
      html.div([attribute.class("error-message")], [
        html.span([], [text(error_msg)]),
        html.button([event.on_click(ClearError)], [text("Dismiss")]),
      ])
    }
  }
}

/// Todo creation form with loading state
fn form_view(model: Model) -> Element(Msg) {
  let is_submitting = is_creating(model)
  let submit_text = case is_submitting {
    True -> "Creating..."
    False -> "Add Todo"
  }

  html.form(
    [
      attribute.class("todo-form"),
      event.on_submit(fn(_form_data) { SubmitForm }),
    ],
    [
      html.input([
        attribute.type_("text"),
        attribute.id("todo-title"),
        attribute.placeholder("Enter todo title..."),
        attribute.value(model.form_title),
        event.on_input(UpdateTitle),
        attribute.disabled(is_submitting),
      ]),
      html.input([
        attribute.type_("text"),
        attribute.id("todo-description"),
        attribute.placeholder("Description (optional)..."),
        attribute.value(model.form_description),
        event.on_input(UpdateDescription),
        attribute.disabled(is_submitting),
      ]),
      html.button(
        [
          attribute.type_("submit"),
          attribute.id("submit-btn"),
          attribute.disabled(is_submitting || model.form_title == ""),
          case is_submitting {
            True -> attribute.attribute("data-loading", "true")
            False -> attribute.attribute("data-loading", "false")
          },
        ],
        [text(submit_text)],
      ),
    ],
  )
}

/// Todo list view with loading indicator
fn todo_list_view(model: Model) -> Element(Msg) {
  let is_loading = is_list_loading(model)

  let loading_indicator = case is_loading {
    True -> html.div(
      [attribute.id("loading-indicator")],
      [text("Loading...")],
    )
    False -> html.div(
      [attribute.id("loading-indicator"), attribute.class("hidden")],
      [],
    )
  }

  html.div(
    [
      attribute.id("todo-list"),
      attribute.class("todo-list-container"),
    ],
    [
      // Loading indicator
      loading_indicator,
      // Todo list
      html.ul(
        [
          attribute.id("todos"),
          case is_loading {
            True -> attribute.attribute("aria-busy", "true")
            False -> attribute.attribute("aria-busy", "false")
          },
        ],
        list.map(model.todos, fn(todo_item) { todo_item_view(model, todo_item) }),
      ),
    ],
  )
}

/// Individual todo item view with loading states
fn todo_item_view(model: Model, todo_item: Todo) -> Element(Msg) {
  let is_todo_updating = is_updating(model, todo_item.id)
  let is_todo_deleting = is_deleting(model, todo_item.id)
  let is_any_operation = is_todo_updating || is_todo_deleting

  let priority_class = case todo_item.priority {
    Low -> "priority-low"
    Medium -> "priority-medium"
    High -> "priority-high"
  }

  let delete_text = case is_todo_deleting {
    True -> "Deleting..."
    False -> "Delete"
  }

  html.li(
    [
      attribute.attribute("data-todo-id", todo_item.id),
      attribute.class(priority_class),
    ],
    [
      // Toggle checkbox
      html.input(
        [
          attribute.type_("checkbox"),
          attribute.class("todo-toggle"),
          attribute.attribute("data-id", todo_item.id),
          attribute.checked(todo_item.completed),
          attribute.disabled(is_todo_updating || is_todo_deleting),
          case is_todo_updating {
            True -> attribute.attribute("data-updating", "true")
            False -> attribute.attribute("data-updating", "false")
          },
          event.on_check(fn(checked) { ToggleTodo(todo_item.id, checked) }),
        ],
      ),
      // Todo title
      html.span(
        case todo_item.completed {
          True -> [attribute.class("completed")]
          False -> []
        },
        [text(todo_item.title)],
      ),
      // Delete button
      html.button(
        [
          attribute.class("delete-btn"),
          attribute.attribute("data-id", todo_item.id),
          attribute.disabled(is_any_operation),
          case is_todo_deleting {
            True -> attribute.attribute("data-deleting", "true")
            False -> attribute.attribute("data-deleting", "false")
          },
          event.on_click(DeleteTodo(todo_item.id)),
        ],
        [text(delete_text)],
      ),
    ],
  )
}
