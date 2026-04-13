/// View rendering for todo application with empty states

import frontend/model.{type Filter, type Model, type Todo, All, Active, Completed, filter_name, filter_todos}
import frontend/msg.{type Msg, SetFilter, SetTitle, SetDescription, SetPriority, SubmitForm, ToggleTodo, DeleteTodo}
import gleam/list
import gleam/option.{Some, None}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [text("boba-raider-8")]),
    render_add_form(model),
    render_filter_buttons(model.filter),
    render_error(model.error),
    render_todo_list(model),
  ])
}

/// Render the add todo form
fn render_add_form(model: Model) -> Element(Msg) {
  html.form(
    [
      attribute.class("add-todo-form"),
      event.on_submit(fn(_) { SubmitForm }),
    ],
    [
      html.input([
        attribute.type_("text"),
        attribute.name("title"),
        attribute.id("todo-title"),
        attribute.placeholder("Enter todo title"),
        attribute.required(True),
        attribute.value(model.form.title),
        event.on_input(SetTitle),
      ]),
      html.input([
        attribute.type_("text"),
        attribute.name("description"),
        attribute.placeholder("Enter description (optional)"),
        attribute.value(model.form.description),
        event.on_input(SetDescription),
      ]),
      html.select(
        [attribute.name("priority"), event.on_input(SetPriority)],
        [
          html.option(
            [attribute.value("low"), selected_if(model.form.priority == "low")],
            "Low"
          ),
          html.option(
            [attribute.value("medium"), selected_if(model.form.priority == "medium")],
            "Medium"
          ),
          html.option(
            [attribute.value("high"), selected_if(model.form.priority == "high")],
            "High"
          ),
        ]
      ),
      html.button([attribute.type_("submit")], [text("Add")]),
    ]
  )
}

fn selected_if(condition: Bool) -> attribute.Attribute(Msg) {
  case condition {
    True -> attribute.selected(True)
    False -> attribute.attribute("", "")
  }
}

/// Render filter selection buttons
fn render_filter_buttons(current_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filter-buttons")], [
    render_filter_button("All", All, current_filter),
    render_filter_button("Active", Active, current_filter),
    render_filter_button("Completed", Completed, current_filter),
  ])
}

fn render_filter_button(label: String, filter: Filter, current: Filter) -> Element(Msg) {
  let is_active = current == filter

  html.button(
    [
      attribute.class(case is_active {
        True -> "filter-button active"
        False -> "filter-button"
      }),
      attribute.attribute("data-filter", filter_name(filter)),
      event.on_click(SetFilter(filter)),
    ],
    [text(label)]
  )
}

/// Render error message if present
fn render_error(error: option.Option(String)) -> Element(Msg) {
  case error {
    Some(msg) -> html.div([attribute.class("error-message")], [text(msg)])
    None -> html.div([], [])
  }
}

/// Render the todo list container with empty state handling
fn render_todo_list(model: Model) -> Element(Msg) {
  let filtered = filter_todos(model)
  let has_todos = case filtered {
    [] -> False
    _ -> True
  }

  html.div(
    [
      attribute.class("todo-list"),
      attribute.attribute("data-testid", "todo-list"),
    ],
    case has_todos {
      True -> list.map(filtered, render_todo_item)
      False -> [render_empty_state(model.filter, model.todos)]
    }
  )
}

/// Render empty state message based on context
/// Boundary contract: No todos at all: 'No todos yet. Add one above!'
/// Boundary contract: No matching filter: 'No {filter} todos.' (e.g., 'No active todos.')
fn render_empty_state(filter: Filter, _all_todos: List(Todo)) -> Element(Msg) {
  let message = case filter {
    All -> "No todos yet. Add one above!"
    Active -> "No active todos."
    Completed -> "No completed todos."
  }

  html.div(
    [
      attribute.class("empty-state"),
      attribute.attribute("data-testid", "empty-state"),
    ],
    [text(message)]
  )
}

/// Render a single todo item
fn render_todo_item(item: Todo) -> Element(Msg) {
  html.div(
    [
      attribute.class(case item.completed {
        True -> "todo-item completed"
        False -> "todo-item"
      }),
      attribute.attribute("data-todo-id", item.id),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
        event.on_click(ToggleTodo(item.id)),
      ]),
      html.div([attribute.class("todo-content")], [
        html.span([attribute.class("todo-title")], [text(item.title)]),
        case item.description {
          Some(desc) if desc != "" ->
            html.span([attribute.class("todo-description")], [text(desc)])
          _ -> html.span([], [])
        },
        html.span([attribute.class("todo-priority")], [text(item.priority)]),
      ]),
      html.button(
        [
          attribute.class("delete-button"),
          event.on_click(DeleteTodo(item.id)),
        ],
        [text("Delete")]
      ),
    ]
  )
}
