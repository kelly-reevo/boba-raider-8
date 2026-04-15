/// Todo view components with data-testid attributes for testability

import frontend/todo_model.{type Filter, type Todo, type TodoModel, All, Active, Completed}
import frontend/todo_msg.{type TodoMsg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view rendering the complete todo application
pub fn view(model: TodoModel) -> Element(TodoMsg) {
  html.div(
    [attribute.class("todo-app"), attribute.attribute("data-testid", "todo-app")],
    [
      header_view(model),
      filter_bar_view(model.filter),
      todo_list_view(model),
      error_view(model.error),
      loading_view(model.loading),
    ],
  )
}

/// Header with active counter display
fn header_view(model: TodoModel) -> Element(TodoMsg) {
  html.header([attribute.class("todo-header")], [
    html.h1([], [element.text("Todo List")]),
    html.span(
      [
        attribute.class("active-counter"),
        attribute.attribute("data-testid", "active-counter-display"),
      ],
      [element.text(todo_model.format_active_count(model.active_count))],
    ),
  ])
}

/// Filter bar with All/Active/Completed buttons
fn filter_bar_view(current_filter: Filter) -> Element(TodoMsg) {
  html.div([attribute.class("filter-bar")], [
    filter_button(All, current_filter),
    filter_button(Active, current_filter),
    filter_button(Completed, current_filter),
  ])
}

/// Individual filter button with active state
fn filter_button(filter: Filter, current: Filter) -> Element(TodoMsg) {
  let label = case filter {
    All -> "All"
    Active -> "Active"
    Completed -> "Completed"
  }

  let test_id = case filter {
    All -> "filter-all-btn"
    Active -> "filter-active-btn"
    Completed -> "filter-completed-btn"
  }

  let is_active = filter == current
  let base_class = "filter-btn"
  let class = case is_active {
    True -> base_class <> " active"
    False -> base_class
  }

  html.button(
    [
      attribute.class(class),
      attribute.attribute("data-testid", test_id),
      event.on_click(todo_msg.SetFilter(filter)),
    ],
    [element.text(label)],
  )
}

/// Todo list container with filtered items
fn todo_list_view(model: TodoModel) -> Element(TodoMsg) {
  let filtered_todos = todo_model.filter_todos(model.todos, model.filter)

  case filtered_todos {
    [] -> empty_list_view()
    todos ->
      html.ul(
        [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list-container")],
        list.map(todos, todo_item_view),
      )
  }
}

/// Empty state when no todos to display
fn empty_list_view() -> Element(TodoMsg) {
  html.div(
    [attribute.class("todo-list-empty"), attribute.attribute("data-testid", "todo-list-empty")],
    [element.text("No todos to display")],
  )
}

/// Individual todo item row with checkbox and text
fn todo_item_view(item: Todo) -> Element(TodoMsg) {
  let item_class = case item.completed {
    True -> "todo-item todo-completed"
    False -> "todo-item"
  }

  let text_decoration = case item.completed {
    True -> "line-through"
    False -> "none"
  }

  let test_id_suffix = item.id

  html.li(
    [
      attribute.class(item_class),
      attribute.attribute("data-testid", "todo-item-" <> test_id_suffix),
      attribute.attribute("data-todo-id", item.id),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.class("todo-checkbox"),
        attribute.attribute("data-testid", "todo-checkbox-" <> test_id_suffix),
        attribute.attribute("data-todo-checkbox-id", item.id),
        attribute.checked(item.completed),
        event.on_check(fn(_) { todo_msg.ToggleTodo(item.id) }),
      ]),
      html.span(
        [
          attribute.class("todo-text"),
          attribute.attribute("data-testid", "todo-item-text-" <> test_id_suffix),
          attribute.attribute("style", "text-decoration: " <> text_decoration <> ";"),
        ],
        [element.text(item.title)],
      ),
      delete_button_view(item.id),
    ],
  )
}

/// Delete button for a todo item
fn delete_button_view(id: String) -> Element(TodoMsg) {
  html.button(
    [
      attribute.class("delete-btn"),
      attribute.attribute("data-testid", "todo-delete-btn-" <> id),
      event.on_click(todo_msg.DeleteTodo(id)),
    ],
    [element.text("Delete")],
  )
}

/// Error message display
fn error_view(error: String) -> Element(TodoMsg) {
  case error {
    "" -> element.none()
    msg ->
      html.div(
        [
          attribute.class("error-message"),
          attribute.attribute("data-testid", "todo-error"),
        ],
        [
          element.text(msg),
          html.button(
            [
              attribute.class("error-dismiss"),
              attribute.attribute("data-testid", "clear-error-btn"),
              event.on_click(todo_msg.ClearError),
            ],
            [element.text("Dismiss")],
          ),
        ],
      )
  }
}

/// Loading indicator
fn loading_view(loading: Bool) -> Element(TodoMsg) {
  case loading {
    False -> element.none()
    True ->
      html.div(
        [attribute.class("loading"), attribute.attribute("data-testid", "todo-loading")],
        [element.text("Loading...")],
      )
  }
}
