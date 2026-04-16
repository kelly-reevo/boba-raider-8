/// HTML rendering for the todo application
/// Includes all states: loading, empty, error, and populated

import frontend/filter
import frontend/model.{type FilterState, type Model}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared

/// Main view function rendering the full application
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Header
    html.h1([], [element.text("Todo App")]),

    // Error display (conditional)
    render_error(model.error),

    // Create todo form
    render_create_form(model),

    // Filter buttons
    render_filter_buttons(model.filter),

    // Loading state or todo list
    render_content(model),

    // Stats footer
    render_stats(model),
  ])
}

/// Render error message if present
fn render_error(error: String) -> Element(Msg) {
  case error {
    "" ->
      // No error - render nothing
      html.div([], [])
    _ ->
      html.div(
        [attribute.class("error-message"), attribute.attribute("data-testid", "todo-error")],
        [element.text(error)],
      )
  }
}

/// Render the create todo form with all fields
fn render_create_form(model: Model) -> Element(Msg) {
  html.div([attribute.class("create-form")], [
    // Title input
    html.div([attribute.class("form-field")], [
      html.label([], [element.text("Title")]),
      html.input([
        attribute.type_("text"),
        attribute.placeholder("What needs to be done?"),
        attribute.value(model.form_title),
        event.on_input(msg.SetFormTitle),
        attribute.attribute("data-testid", "form-title-input"),
      ]),
    ]),
    // Description input
    html.div([attribute.class("form-field")], [
      html.label([], [element.text("Description")]),
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Add details (optional)"),
        attribute.value(model.form_description),
        event.on_input(msg.SetFormDescription),
        attribute.attribute("data-testid", "form-description-input"),
      ]),
    ]),
    // Priority select
    html.div([attribute.class("form-field")], [
      html.label([], [element.text("Priority")]),
      html.select(
        [event.on_input(handle_priority_change), attribute.attribute("data-testid", "form-priority-input")],
        [
          html.option([attribute.value("high"), attribute.selected(model.form_priority == shared.High)], "High"),
          html.option([attribute.value("medium"), attribute.selected(model.form_priority == shared.Medium)], "Medium"),
          html.option([attribute.value("low"), attribute.selected(model.form_priority == shared.Low)], "Low"),
        ],
      ),
    ]),
    // Submit button
    html.button(
      [
        event.on_click(msg.SubmitCreateTodo),
        attribute.disabled(model.loading),
        attribute.attribute("data-testid", "submit-create-todo-btn"),
      ],
      [element.text("Add Todo")],
    ),
  ])
}

/// Handle priority dropdown change
fn handle_priority_change(value: String) -> Msg {
  case value {
    "high" -> msg.SetFormPriority(shared.High)
    "medium" -> msg.SetFormPriority(shared.Medium)
    "low" -> msg.SetFormPriority(shared.Low)
    _ -> msg.SetFormPriority(shared.Medium)
  }
}

/// Render filter buttons
fn render_filter_buttons(current_filter: FilterState) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    filter_button("All", model.All, current_filter),
    filter_button("Active", model.Active, current_filter),
    filter_button("Completed", model.Completed, current_filter),
  ])
}

fn filter_button(label: String, filter_state: FilterState, current: FilterState) -> Element(Msg) {
  let is_active = filter_state == current
  let base_testid = case filter_state {
    model.All -> "all"
    model.Active -> "active"
    model.Completed -> "completed"
  }
  html.button(
    [
      event.on_click(msg.SetFilter(filter_state)),
      attribute.class("filter-btn " <> case is_active { True -> "active" False -> "" }),
      attribute.disabled(is_active),
      attribute.attribute("data-testid", "filter-" <> base_testid <> "-btn"),
    ],
    [element.text(label)],
  )
}

/// Render main content area: loading, empty, or todo list
fn render_content(model: Model) -> Element(Msg) {
  case model.loading {
    True -> render_loading()
    False -> {
      let visible_todos = model.filter_todos(model)
      case list.is_empty(visible_todos) {
        True -> render_empty_state(model.filter)
        False -> render_todo_list(visible_todos)
      }
    }
  }
}

/// Render loading state
fn render_loading() -> Element(Msg) {
  html.div(
    [attribute.class("loading-state"), attribute.attribute("data-testid", "todos-loading")],
    [element.text("Loading...")],
  )
}

/// Render empty state based on current filter
fn render_empty_state(filter_state: FilterState) -> Element(Msg) {
  let message = case filter_state {
    model.All -> "No todos yet. Create one above!"
    model.Active -> "No active todos. Great job!"
    model.Completed -> "No completed todos yet."
  }
  html.div(
    [attribute.class("empty-state"), attribute.attribute("data-testid", "todos-empty")],
    [element.text(message)],
  )
}

/// Render the todo list
fn render_todo_list(todos: List(shared.Todo)) -> Element(Msg) {
  html.ul(
    [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")],
    list.map(todos, render_todo_item),
  )
}

/// Render a single todo item
fn render_todo_item(item: shared.Todo) -> Element(Msg) {
  let completed_class = case item.completed {
    True -> "completed"
    False -> ""
  }

  let priority_class = case item.priority {
    shared.High -> "priority-high"
    shared.Medium -> "priority-medium"
    shared.Low -> "priority-low"
  }

  html.li(
    [
      attribute.class("todo-item " <> completed_class <> " " <> priority_class),
      attribute.attribute("data-testid", "todo-item-" <> item.id),
    ],
    [
      // Checkbox for toggle
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
        event.on_check(fn(checked) { msg.ToggleTodo(item.id, checked) }),
        attribute.attribute("data-testid", "toggle-todo-" <> item.id),
      ]),
      // Todo content
      html.div([attribute.class("todo-content")], [
        html.span([attribute.class("todo-title")], [element.text(item.title)]),
        // Optional description
        case item.description {
          option.Some(desc) ->
            html.span([attribute.class("todo-description")], [element.text(desc)])
          option.None ->
            html.span([], [])
        },
        html.span([attribute.class("todo-priority")], [
          element.text(case item.priority {
            shared.High -> "High"
            shared.Medium -> "Medium"
            shared.Low -> "Low"
          }),
        ]),
      ]),
      // Delete button
      html.button(
        [
          event.on_click(msg.DeleteTodo(item.id)),
          attribute.class("delete-btn"),
          attribute.attribute("data-testid", "delete-todo-" <> item.id),
        ],
        [element.text("Delete")],
      ),
    ],
  )
}

/// Render stats footer
fn render_stats(model: Model) -> Element(Msg) {
  let total = list.length(model.todos)
  let active = count_active(model.todos)
  let completed = total - active

  html.div([attribute.class("stats"), attribute.attribute("data-testid", "todo-stats")], [
    element.text(
      int.to_string(total) <> " total, " <> int.to_string(active) <> " active, " <> int.to_string(
        completed,
      ) <> " completed",
    ),
  ])
}

fn count_active(todos: List(shared.Todo)) -> Int {
  do_count_active(todos, 0)
}

fn do_count_active(todos: List(shared.Todo), acc: Int) -> Int {
  case todos {
    [] -> acc
    [first, ..rest] -> {
      let new_acc = case first.completed {
        False -> acc + 1
        True -> acc
      }
      do_count_active(rest, new_acc)
    }
  }
}
