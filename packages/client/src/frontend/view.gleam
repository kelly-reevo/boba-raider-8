/// View rendering with loading states and disabled controls

import frontend/model.{type Model, is_globally_loading, is_todo_deleting, is_todo_saving}
import frontend/msg.{
  type Msg, AddTodo, DeleteData, DeleteTodo, SetFilter, Start, ToggleData,
  ToggleTodo, UpdateDescription, UpdateTitle,
}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared.{type Todo, Active, All, Completed}

/// Main view function
pub fn view(m: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [text("Todo List")]),
    render_error(m.error),
    render_loading_indicator(m),
    render_filter_buttons(m),
    render_add_todo_form(m),
    render_todo_list(m),
  ])
}

/// Render error message if present
fn render_error(error: String) -> Element(Msg) {
  case error {
    "" -> html.div([], [])
    _ ->
      html.div(
        [attribute.class("error-message"), attribute.attribute("data-testid", "error-message")],
        [text(error)],
      )
  }
}

/// Render loading indicator with appropriate text
fn render_loading_indicator(m: Model) -> Element(Msg) {
  let is_visible = m.is_loading || m.is_adding || !list_is_empty(m.saving_todo_ids) || !list_is_empty(m.deleting_todo_ids)

  let display_style = case is_visible {
    True -> "block"
    False -> "none"
  }

  let message = case m.loading_message {
    "" ->
      case m.is_adding {
        True -> "Adding..."
        False ->
          case !list_is_empty(m.saving_todo_ids) {
            True -> "Saving..."
            False ->
              case !list_is_empty(m.deleting_todo_ids) {
                True -> "Deleting..."
                False -> "Loading..."
              }
          }
      }
    msg -> msg
  }

  html.div(
    [
      attribute.id("loading-indicator"),
      attribute.class("loading-indicator"),
      attribute.attribute("data-testid", "loading-indicator"),
      attribute.style("display", display_style),
    ],
    [text(message)],
  )
}

/// Render filter buttons
fn render_filter_buttons(m: Model) -> Element(Msg) {
  let is_disabled = is_globally_loading(m)

  html.div([attribute.class("filter-buttons")], [
    html.button(
      [
        attribute.class(case m.filter {
          All -> "filter-btn active"
          _ -> "filter-btn"
        }),
        attribute.attribute("data-testid", "filter-all-btn"),
        attribute.disabled(is_disabled),
        event.on_click(SetFilter(All)),
      ],
      [text("All")],
    ),
    html.button(
      [
        attribute.class(case m.filter {
          Active -> "filter-btn active"
          _ -> "filter-btn"
        }),
        attribute.attribute("data-testid", "filter-active-btn"),
        attribute.disabled(is_disabled),
        event.on_click(SetFilter(Active)),
      ],
      [text("Active")],
    ),
    html.button(
      [
        attribute.class(case m.filter {
          Completed -> "filter-btn active"
          _ -> "filter-btn"
        }),
        attribute.attribute("data-testid", "filter-completed-btn"),
        attribute.disabled(is_disabled),
        event.on_click(SetFilter(Completed)),
      ],
      [text("Completed")],
    ),
  ])
}

/// Render add todo form with disabled states
fn render_add_todo_form(m: Model) -> Element(Msg) {
  let is_disabled = is_globally_loading(m)

  html.form(
    [
      attribute.class("add-todo-form"),
      attribute.attribute("data-testid", "add-todo-form"),
      event.on_submit(fn(_) {
        AddTodo(
          Start,
          msg.AddFormData(title: m.new_todo_title, description: m.new_todo_description),
        )
      }),
    ],
    [
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Todo title"),
        attribute.value(m.new_todo_title),
        attribute.attribute("data-testid", "todo-title-input"),
        attribute.disabled(is_disabled),
        event.on_input(UpdateTitle),
      ]),
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Description (optional)"),
        attribute.value(m.new_todo_description),
        attribute.attribute("data-testid", "todo-description-input"),
        attribute.disabled(is_disabled),
        event.on_input(UpdateDescription),
      ]),
      html.button(
        [
          attribute.type_("submit"),
          attribute.attribute("data-testid", "add-todo-submit-btn"),
          attribute.disabled(is_disabled || string_is_empty(m.new_todo_title)),
        ],
        [text(m.submit_button_text)],
      ),
    ],
  )
}

/// Render the todo list
fn render_todo_list(m: Model) -> Element(Msg) {
  let visible_todos = case m.filter {
    All -> m.todos
    Active -> list_filter(m.todos, fn(t) { !t.completed })
    Completed -> list_filter(m.todos, fn(t) { t.completed })
  }

  let items = case list_is_empty(visible_todos) {
    True ->
      case m.is_loading {
        True -> [html.div([attribute.class("empty-state")], [text("")])]
        False -> [html.div([attribute.class("empty-state"), attribute.attribute("data-testid", "todo-list-empty")], [text("No todos found")])]
      }
    False -> list_map(visible_todos, render_todo_item(m))
  }

  html.div([attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")], items)
}

/// Render a single todo item
fn render_todo_item(m: Model) -> fn(Todo) -> Element(Msg) {
  fn(item: Todo) {
    let is_saving = is_todo_saving(m, item.id)
    let is_deleting = is_todo_deleting(m, item.id)
    let is_busy = is_saving || is_deleting || is_globally_loading(m)

    let checkbox_disabled = is_busy
    let delete_disabled = is_busy

    let checkbox_testid = "todo-checkbox-" <> item.id
    let delete_testid = "delete-todo-btn-" <> item.id

    let delete_button_text = case is_deleting {
      True -> "Deleting..."
      False -> "Delete"
    }

    html.div(
      [
        attribute.class(case item.completed {
          True -> "todo-item completed"
          False -> "todo-item"
        }),
        attribute.attribute("data-testid", "todo-item-" <> item.id),
      ],
      [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(item.completed),
          attribute.attribute("data-testid", checkbox_testid),
          attribute.disabled(checkbox_disabled),
          event.on_click(ToggleTodo(Start, ToggleData(id: item.id, completed: !item.completed))),
        ]),
        html.span([attribute.class("todo-title")], [text(item.title)]),
        html.button(
          [
            attribute.class("delete-btn"),
            attribute.attribute("data-testid", delete_testid),
            attribute.disabled(delete_disabled),
            event.on_click(DeleteTodo(Start, DeleteData(item.id))),
          ],
          [text(delete_button_text)],
        ),
      ],
    )
  }
}

// Helper functions

fn list_is_empty(list: List(a)) -> Bool {
  case list {
    [] -> True
    _ -> False
  }
}

fn list_map(list: List(a), f: fn(a) -> b) -> List(b) {
  case list {
    [] -> []
    [first, ..rest] -> [f(first), ..list_map(rest, f)]
  }
}

fn list_filter(list: List(a), predicate: fn(a) -> Bool) -> List(a) {
  case list {
    [] -> []
    [first, ..rest] ->
      case predicate(first) {
        True -> [first, ..list_filter(rest, predicate)]
        False -> list_filter(rest, predicate)
      }
  }
}

fn string_is_empty(s: String) -> Bool {
  case s {
    "" -> True
    _ -> False
  }
}
