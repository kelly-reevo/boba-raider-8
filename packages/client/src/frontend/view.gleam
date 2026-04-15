import frontend/filter
import frontend/model.{type Filter, type Model}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Todo App")]),
    // Input section
    html.div([attribute.class("input-section")], [
      html.input([
        attribute.type_("text"),
        attribute.placeholder("What needs to be done?"),
        attribute.value(model.input_text),
        event.on_input(msg.UpdateInput),
        attribute.attribute("data-testid", "todo-input"),
      ]),
      html.button(
        [
          event.on_click(msg.AddTodo),
          attribute.attribute("data-testid", "add-todo-btn"),
        ],
        [element.text("Add")],
      ),
    ]),
    // Filter buttons
    html.div([attribute.class("filters")], [
      filter_button("All", filter.All, model.filter),
      filter_button("Active", filter.Active, model.filter),
      filter_button("Completed", filter.Completed, model.filter),
    ]),
    // Todo list
    render_todo_list(model),
    // Stats
    html.div([attribute.class("stats")], [
      element.text(
        int.to_string(list.length(model.todos)) <> " items total, " <> int.to_string(
          list.length(list.filter(model.todos, fn(t) { !t.completed })),
        ) <> " active",
      ),
    ]),
  ])
}

fn filter_button(label: String, filter: Filter, current: Filter) -> Element(Msg) {
  let is_active = case filter == current {
    True -> "active"
    False -> ""
  }
  html.button(
    [
      event.on_click(msg.SetFilter(filter)),
      attribute.class("filter-btn " <> is_active),
      attribute.attribute("data-testid", "filter-" <> label <> "-btn"),
    ],
    [element.text(label)],
  )
}

fn render_todo_list(model: Model) -> Element(Msg) {
  let visible_todos = filter.filter_todos(model.todos, model.filter)

  case list.is_empty(visible_todos) {
    True ->
      html.div(
        [attribute.class("empty-state"), attribute.attribute("data-testid", "todo-empty")],
        [element.text("No todos to display")],
      )
    False ->
      html.ul(
        [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")],
        list.map(visible_todos, render_todo_item),
      )
  }
}

fn render_todo_item(item: filter.TodoItem) -> Element(Msg) {
  let completed_class = case item.completed {
    True -> "completed"
    False -> ""
  }

  html.li(
    [
      attribute.class("todo-item " <> completed_class),
      attribute.attribute("data-testid", "todo-item-" <> item.id),
    ],
    [
      html.input([
        attribute.type_("checkbox"),
        attribute.checked(item.completed),
        event.on_click(msg.ToggleTodo(item.id)),
        attribute.attribute("data-testid", "toggle-todo-" <> item.id),
      ]),
      html.span([attribute.class("todo-title")], [element.text(item.title)]),
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
