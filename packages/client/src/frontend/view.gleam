import frontend/model.{type Filter, type Model, All, Active, Completed}
import frontend/msg.{type Msg, FilterChanged}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo List")]),
    render_filter_controls(model.filter),
    render_todo_list(model),
  ])
}

/// Render filter controls as button group
fn render_filter_controls(current_filter: Filter) -> Element(Msg) {
  html.div(
    [attribute.class("filter-controls")],
    [
      filter_button("All", All, current_filter),
      filter_button("Active", Active, current_filter),
      filter_button("Completed", Completed, current_filter),
    ],
  )
}

/// Individual filter button with active state
fn filter_button(
  label: String,
  filter_value: Filter,
  current_filter: Filter,
) -> Element(Msg) {
  let is_active = filter_value == current_filter
  let filter_str = case filter_value {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }

  html.button(
    [
      attribute.class(
        string.concat(["filter-btn", case is_active {
          True -> " active"
          False -> ""
        }]),
      ),
      attribute.attribute("data-filter", filter_str),
      attribute.attribute("aria-pressed", case is_active {
        True -> "true"
        False -> "false"
      }),
      event.on_click(FilterChanged(filter_value)),
    ],
    [element.text(label)],
  )
}

/// Render the todo list based on model state
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-list-container")], [
    case model.loading {
      True -> html.div([attribute.class("loading")], [element.text("Loading...")])
      False -> element.none()
    },
    case string.is_empty(model.error) {
      False -> html.div([attribute.class("error")], [element.text(model.error)])
      True -> element.none()
    },
    html.ul(
      [attribute.id("todo-list")],
      case list.is_empty(model.todos) && !model.loading {
        True -> [html.li([attribute.class("empty")], [element.text("No todos")])]
        False -> list.map(model.todos, render_todo_item)
      },
    ),
  ])
}

/// Render a single todo item
fn render_todo_item(item: Todo) -> Element(Msg) {
  html.li(
    [
      attribute.attribute("data-id", item.id),
      attribute.class(case item.completed {
        True -> "completed"
        False -> ""
      }),
    ],
    [element.text(item.title)],
  )
}
