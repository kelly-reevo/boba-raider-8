import frontend/model.{type Filter, type Model, Active, All, Completed}
import frontend/msg.{type Msg}
import frontend/update
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Render the complete application view
/// Includes: filter controls, todo list with all states
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_filter_controls(model.filter),
    render_todo_list(model),
    render_status_message(model.error),
  ])
}

/// Filter controls: All | Active | Completed
/// Active button has 'active' CSS class
fn render_filter_controls(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.id("filter-controls")], [
    render_filter_button(All, "all", current_filter),
    render_filter_button(Active, "active", current_filter),
    render_filter_button(Completed, "completed", current_filter),
  ])
}

/// Single filter button with data-filter attribute and active class
fn render_filter_button(
  filter: Filter,
  filter_name: String,
  current: Filter,
) -> Element(Msg) {
  let is_active = filter == current
  let attrs = case is_active {
    True -> [
      attribute.attribute("data-filter", filter_name),
      attribute.class("active"),
      event.on_click(msg.SetFilter(filter)),
    ]
    False -> [
      attribute.attribute("data-filter", filter_name),
      event.on_click(msg.SetFilter(filter)),
    ]
  }
  html.button(attrs, [element.text(capitalize(filter_name))])
}

/// Capitalize first letter for button text
fn capitalize(s: String) -> String {
  case s {
    "all" -> "All"
    "active" -> "Active"
    "completed" -> "Completed"
    _ -> s
  }
}

/// Render todo list with all states: loading, empty, error, populated
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.id("todo-list")], case model.loading {
    True -> [element.text("Loading...")]
    False -> {
      let filtered = update.apply_filter(model.todos, model.filter)
      case filtered {
        [] -> {
          case model.todos {
            [] -> [element.text("No todos yet. Add one above!")]
            _ -> [element.text("No todos match the current filter.")]
          }
        }
        todos -> list.map(todos, render_todo_item)
      }
    }
  })
}

/// Render a single todo item
fn render_todo_item(todo_item: Todo) -> Element(Msg) {
  let completed_class = case todo_item.completed {
    True -> "completed"
    False -> ""
  }
  html.div(
    [
      attribute.class("todo-item " <> completed_class),
      attribute.attribute("data-id", todo_item.id),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.class("todo-toggle"),
        attribute.checked(todo_item.completed),
      ]),
      html.span([attribute.class("todo-title")], [element.text(todo_item.title)]),
      html.button([attribute.class("todo-delete-btn")], [element.text("Delete")]),
    ],
  )
}

/// Render status/error message
fn render_status_message(error: String) -> Element(Msg) {
  let content = case error {
    "" -> element.text("")
    msg -> element.text(msg)
  }
  html.div([attribute.id("status-message")], [content])
}
