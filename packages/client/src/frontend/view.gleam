/// HTML rendering

import frontend/model.{type Model}
import frontend/msg.{type Msg, FilterChanged, Increment, Decrement, Reset}
import frontend/todo_types.{type Filter, type Todo, All, Active, Completed}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

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

    // Todo filter section
    render_filter_section(model),
  ])
}

fn render_filter_section(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-section")], [
    html.h2([], [element.text("Todos")]),

    // Filter buttons
    render_filter_buttons(model.current_filter),

    // Todo list
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

fn render_todo_list(model: Model) -> Element(Msg) {
  // Show loading state
  case model.loading {
    True ->
      html.div(
        [
          attribute.class("todo-loading"),
          attribute.attribute("data-testid", "todo-loading"),
        ],
        [element.text("Loading...")],
      )
    False -> {
      // Show error state
      case model.error {
        "" -> render_todo_items(model.todos)
        err ->
          html.div(
            [
              attribute.class("todo-error"),
              attribute.attribute("data-testid", "todo-error"),
            ],
            [element.text("Error: " <> err)],
          )
      }
    }
  }
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
      attribute.attribute("data-testid", "todo-item"),
      attribute.attribute("data-completed", case todo_item.completed {
        True -> "true"
        False -> "false"
      }),
    ],
    [element.text(todo_item.title)],
  )
}
