import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Main application content
    html.h1([], [element.text("boba-raider-8")]),
    html.button([event.on_click(msg.FetchTodos)], [element.text("Load Todos")]),
    render_content(model),
  ])
}

/// Render appropriate content based on model state
fn render_content(model: Model) -> Element(Msg) {
  case model.loading, model.error, model.todos {
    // Loading state
    True, _, _ -> html.div([attribute.class("loading")], [element.text("Loading...")])

    // Error state
    False, error, _ if error != "" ->
      html.div([attribute.class("error-message")], [element.text(error)])

    // Empty state - no todos
    False, _, [] ->
      html.div([attribute.class("empty-state")], [element.text("No todos yet. Add one above!")])

    // Populated state - render todos
    False, _, todos ->
      html.ul(
        [attribute.id("todo-list")],
        list.map(todos, render_todo_item),
      )
  }
}

/// Render a single todo item as li element
/// <li data-id='{id}'>
///   <input type='checkbox' class='toggle' checked={completed}>
///   <span class='title'>{title}</span>
///   <span class='priority priority-{priority}'>{priority}</span>
///   <button class='delete'>Delete</button>
/// </li>
fn render_todo_item(item: Todo) -> Element(Msg) {
  let priority_class = "priority priority-" <> item.priority

  let completed_class = case item.completed {
    True -> "todo-item completed"
    False -> "todo-item"
  }

  let data_completed = case item.completed {
    True -> "true"
    False -> "false"
  }

  html.li(
    [
      attribute.class(completed_class),
      attribute.attribute("data-id", item.id),
    ],
    [
      // Checkbox for completion status
      html.input([
        attribute.type_("checkbox"),
        attribute.class("toggle"),
        attribute.checked(item.completed),
        attribute.attribute("data-completed", data_completed),
        event.on_check(msg.ToggleTodo(item.id, _)),
      ]),
      // Title span
      html.span([attribute.class("title")], [element.text(item.title)]),
      // Priority indicator span
      html.span(
        [attribute.class(priority_class)],
        [element.text(item.priority)],
      ),
      // Delete button
      html.button(
        [attribute.class("delete"), event.on_click(msg.DeleteTodo(item.id))],
        [element.text("Delete")],
      ),
    ],
  )
}
