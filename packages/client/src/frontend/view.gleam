/// View rendering - HTML generation

import frontend/model.{type Model, Idle, Loading, Error}
import frontend/msg.{type Msg}
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo, Low, Medium, High}

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_form(model),
    render_error(model),
    render_todo_list(model),
  ])
}

/// Render the todo creation form
fn render_form(model: Model) -> Element(Msg) {
  html.form(
    [
      attribute.id("todo-form"),
      // Prevent default submission via attribute, handle via button click
      attribute.attribute("onsubmit", "event.preventDefault(); return false;"),
    ],
    [
      // Title input
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-title")], [element.text("Title")]),
        html.input([
          attribute.id("todo-title"),
          attribute.type_("text"),
          attribute.value(model.form.title),
          event.on_input(msg.TitleChanged),
        ]),
      ]),

      // Description textarea
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-description")], [element.text("Description")]),
        html.textarea(
          [
            attribute.id("todo-description"),
            attribute.value(model.form.description),
            event.on_input(msg.DescriptionChanged),
          ],
          "",
        ),
      ]),

      // Priority select
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("todo-priority")], [element.text("Priority")]),
        html.select(
          [
            attribute.id("todo-priority"),
            event.on_input(fn(value) {
              case value {
                "low" -> msg.PriorityChanged(Low)
                "medium" -> msg.PriorityChanged(Medium)
                "high" -> msg.PriorityChanged(High)
                _ -> msg.PriorityChanged(Medium)
              }
            }),
          ],
          [
            html.option(
              [
                attribute.value("low"),
                attribute.selected(model.form.priority == Low),
              ],
              "Low",
            ),
            html.option(
              [
                attribute.value("medium"),
                attribute.selected(model.form.priority == Medium),
              ],
              "Medium",
            ),
            html.option(
              [
                attribute.value("high"),
                attribute.selected(model.form.priority == High),
              ],
              "High",
            ),
          ],
        ),
      ]),

      // Submit button
      html.button(
        [
          attribute.type_("button"),
          attribute.disabled(model.submit_state == Loading),
          event.on_click(msg.SubmitForm),
        ],
        case model.submit_state {
          Loading -> [element.text("Adding...")]
          _ -> [element.text("Add")]
        },
      ),
    ],
  )
}

/// Render error display area
fn render_error(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.id("error-display"),
      attribute.class(case string.is_empty(model.error) {
        True -> "error-display hidden"
        False -> "error-display"
      }),
    ],
    case string.is_empty(model.error) {
      True -> []
      False -> [element.text(model.error)]
    },
  )
}

/// Render the todo list
fn render_todo_list(model: Model) -> Element(Msg) {
  html.div([attribute.class("todo-list-container")], [
    html.h2([], [element.text("Todos")]),
    html.ul(
      [attribute.id("todo-list")],
      case model.todos {
        [] -> [
          html.li(
            [attribute.class("empty-state")],
            [element.text("No todos yet. Add one above!")],
          ),
        ]
        todos -> list.map(todos, render_todo_item)
      },
    ),
  ])
}

/// Render a single todo item
fn render_todo_item(item: Todo) -> Element(Msg) {
  let priority_class = priority_class_from_string(item.priority)

  html.li(
    [
      attribute.data("id", item.id),
      attribute.class(case item.completed {
        True -> "completed"
        False -> ""
      }),
    ],
    [
      html.span([attribute.class("title")], [element.text(item.title)]),
      html.span(
        [attribute.class("priority " <> priority_class)],
        [element.text(item.priority)],
      ),
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
      ]),
      html.button([attribute.class("delete")], [element.text("Delete")]),
    ],
  )
}

/// Get CSS class from priority string
fn priority_class_from_string(priority: String) -> String {
  case priority {
    "low" -> "priority-low"
    "medium" -> "priority-medium"
    "high" -> "priority-high"
    _ -> "priority-medium"
  }
}
