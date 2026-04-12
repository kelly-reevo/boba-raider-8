/// Todo list view component
/// Renders todo items with title, priority badge, completion checkbox,
/// optional description, and delete button

import frontend/msg.{type Msg, ToggleTodo, DeleteTodo}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared.{type Todo, type Priority, Low, Medium, High}

/// Render a list of todos
pub fn todo_list(todos: List(Todo)) -> Element(Msg) {
  html.div([attribute.class("todo-list")], [
    html.div([attribute.class("todo-list-container")],
      list.map(todos, todo_item)
    ),
  ])
}

/// Render a single todo item
/// Creates DOM structure:
/// <div class="todo-item" data-id="{uuid}">
///   <input type="checkbox" class="toggle-complete">
///   <span class="title">{title}</span>
///   <span class="priority-badge priority-{priority}">{priority}</span>
///   <p class="description">{description}</p>  <!-- only if description exists -->
///   <button class="delete-btn">Delete</button>
/// </div>
pub fn todo_item(item: Todo) -> Element(Msg) {
  let priority_class = case item.priority {
    Low -> "priority-low"
    Medium -> "priority-medium"
    High -> "priority-high"
  }

  let priority_badge = html.span(
    [
      attribute.class("priority-badge " <> priority_class),
    ],
    [text(priority_to_string(item.priority))]
  )

  let description_element = case item.description {
    Some(desc) -> [
      html.p([attribute.class("description")], [text(desc)]),
    ]
    None -> []
  }

  let children = [
    html.input([
      attribute.type_("checkbox"),
      attribute.class("toggle-complete"),
      attribute.checked(item.completed),
      event.on_check(fn(checked) { ToggleTodo(item.id, checked) }),
    ]),
    html.span([attribute.class("title")], [text(item.title)]),
    priority_badge,
  ]

  let children = list.append(children, description_element)

  let children = list.append(children, [
    html.button(
      [
        attribute.class("delete-btn"),
        event.on_click(DeleteTodo(item.id)),
      ],
      [text("Delete")]
    ),
  ])

  html.div(
    [
      attribute.class("todo-item"),
      attribute.attribute("data-id", item.id),
    ],
    children
  )
}

/// Convert priority to string for display
fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}
