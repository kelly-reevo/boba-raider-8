/// HTML rendering for the todo application
/// Includes all states: loading, empty, error, and populated

import frontend/model.{type FilterState, type Model, All, Active, Completed}
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
        [attribute.class("error-message"), attribute.attribute("data-testid", "form-error-message")],
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
        event.on_input(msg.UpdateFormTitle),
        attribute.attribute("data-testid", "todo-title-input"),
      ]),
    ]),
    // Description input
    html.div([attribute.class("form-field")], [
      html.label([], [element.text("Description")]),
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Add details (optional)"),
        attribute.value(case model.form_description {
          option.Some(desc) -> desc
          option.None -> ""
        }),
        event.on_input(msg.UpdateFormDescription),
        attribute.attribute("data-testid", "todo-description-input"),
      ]),
    ]),
    // Priority select
    html.div([attribute.class("form-field")], [
      html.label([], [element.text("Priority")]),
      html.select(
        [event.on_input(msg.UpdateFormPriority), attribute.attribute("data-testid", "todo-priority-select")],
        [
          html.option([attribute.value("high"), attribute.selected(model.form_priority == "high")], "High"),
          html.option([attribute.value("medium"), attribute.selected(model.form_priority == "medium")], "Medium"),
          html.option([attribute.value("low"), attribute.selected(model.form_priority == "low")], "Low"),
        ],
      ),
    ]),
    // Submit button
    html.button(
      [
        event.on_click(msg.SubmitCreateTodo),
        attribute.disabled(model.loading),
        attribute.attribute("data-testid", "todo-submit-btn"),
      ],
      [element.text("Add Todo")],
    ),
  ])
}

/// Render filter buttons
fn render_filter_buttons(current_filter: FilterState) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    filter_button("All", All, current_filter),
    filter_button("Active", Active, current_filter),
    filter_button("Completed", Completed, current_filter),
  ])
}

/// Public filter button element for rendering and testing
/// Shows active state when filter_state matches current filter
pub fn filter_button(label: String, filter_state: FilterState, current: FilterState) -> Element(Msg) {
  let is_active = filter_state == current
  let base_testid = case filter_state {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
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
        True -> render_empty_state(model.filter, model.todos)
        False -> render_todo_list(model, visible_todos)
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

/// Render empty state based on current filter and total todos
fn render_empty_state(filter_state: FilterState, all_todos: List(shared.Todo)) -> Element(Msg) {
  let message = case all_todos {
    [] -> "No todos yet"
    _ -> {
      case filter_state {
        All -> "No todos yet"
        Active -> "No active todos. Great job!"
        Completed -> "No completed todos yet."
      }
    }
  }
  html.div(
    [attribute.class("empty-state"), attribute.attribute("data-testid", "todo-list-empty")],
    [element.text(message)],
  )
}

/// Render the todo list
fn render_todo_list(model: Model, todos: List(shared.Todo)) -> Element(Msg) {
  html.ul(
    [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")],
    list.map(todos, fn(t) { render_todo_item(model, t) }),
  )
}

/// Check if a specific todo is in confirmation state
fn is_confirming_delete(model: Model, todo_id: String) -> Bool {
  case model.delete_confirming_id {
    option.Some(id) if id == todo_id -> True
    _ -> False
  }
}

/// Render delete button or confirmation dialog
fn render_delete_section(model: Model, item: shared.Todo) -> Element(Msg) {
  let is_confirming = is_confirming_delete(model, item.id)

  case is_confirming {
    // Normal delete button
    False ->
      html.button(
        [
          event.on_click(msg.DeleteClicked(item.id)),
          attribute.class("delete-btn"),
          attribute.attribute("data-testid", "delete-btn-" <> item.id),
        ],
        [element.text("Delete")],
      )

    // Confirmation dialog
    True ->
      html.div(
        [attribute.class("confirm-dialog"), attribute.attribute("data-testid", "confirm-dialog")],
        [
          html.span([attribute.class("confirm-text")], [element.text("Delete?")]),
          html.button(
            [
              event.on_click(msg.DeleteClicked(item.id)),
              attribute.class("confirm-delete-btn"),
              attribute.attribute("data-testid", "confirm-delete-btn"),
            ],
            [element.text("Yes")],
          ),
          html.button(
            [
              event.on_click(msg.CancelDelete),
              attribute.class("cancel-delete-btn"),
              attribute.attribute("data-testid", "cancel-delete-btn"),
            ],
            [element.text("No")],
          ),
        ],
      )
  }
}

/// Render a single todo item
fn render_todo_item(model: Model, item: shared.Todo) -> Element(Msg) {
  let completed_class = case item.completed {
    True -> " completed"
    False -> ""
  }

  let priority_class = case item.priority {
    shared.High -> " priority-high"
    shared.Medium -> " priority-medium"
    shared.Low -> " priority-low"
  }

  let is_confirming = is_confirming_delete(model, item.id)
  let confirming_class = case is_confirming {
    True -> " confirming-delete"
    False -> ""
  }

  // Title attributes based on completion state
  let title_attributes = case item.completed {
    True -> [
      attribute.class("todo-title todo-title-completed"),
      attribute.style("text-decoration", "line-through"),
      attribute.attribute("data-testid", "todo-title-" <> item.id),
    ]
    False -> [
      attribute.class("todo-title"),
      attribute.attribute("data-testid", "todo-title-" <> item.id),
    ]
  }

  // Description element (only rendered if present)
  let description_element = case item.description {
    option.Some(desc) ->
      html.div(
        [attribute.class("todo-description"), attribute.attribute("data-testid", "todo-description-" <> item.id)],
        [element.text(desc)],
      )
    option.None -> html.div([], [])
  }

  html.li(
    [
      attribute.class("todo-item" <> completed_class <> priority_class <> confirming_class),
      attribute.attribute("data-testid", "todo-item-" <> item.id),
    ],
    [
      // Checkbox for toggle completion
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
        event.on_check(fn(checked) { msg.ToggleTodo(item.id, checked) }),
        attribute.attribute("data-testid", "todo-checkbox-" <> item.id),
      ]),
      // Todo content
      html.div([attribute.class("todo-content")], [
        html.span(title_attributes, [element.text(item.title)]),
        description_element,
        html.span(
          [attribute.class("todo-priority " <> priority_class), attribute.attribute("data-testid", "todo-priority-" <> item.id)],
          [element.text(priority_text(item.priority))],
        ),
      ]),
      // Delete button or confirmation UI
      render_delete_section(model, item),
    ],
  )
}

fn priority_text(priority: shared.Priority) -> String {
  case priority {
    shared.High -> "High"
    shared.Medium -> "Medium"
    shared.Low -> "Low"
  }
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
