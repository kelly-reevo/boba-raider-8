import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared

/// Render the complete application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_form(model),
    render_todo_list(model.todos),
  ])
}

/// Render the add todo form
fn render_form(model: Model) -> Element(Msg) {
  html.form(
    [
      attribute.id("todo-form"),
      event.on_submit(fn(_) { msg.SubmitForm }),
    ],
    [
      html.input([
        attribute.type_("text"),
        attribute.id("title"),
        attribute.name("title"),
        attribute.placeholder("Title"),
        attribute.value(model.form_title),
        event.on_input(msg.TitleChanged),
      ]),
      html.textarea(
        [
          attribute.id("description"),
          attribute.name("description"),
          attribute.placeholder("Description"),
          event.on_input(msg.DescriptionChanged),
        ],
        model.form_description,
      ),
      html.button(
        [
          attribute.type_("submit"),
          case model.loading {
            True -> attribute.disabled(True)
            False -> attribute.none()
          },
        ],
        case model.loading {
          True -> [element.text("Adding...")]
          False -> [element.text("Add Todo")]
        },
      ),
      render_error_container(model.form_error),
    ],
  )
}

/// Render the error container
fn render_error_container(error: String) -> Element(Msg) {
  case error {
    "" ->
      html.div([attribute.id("error-container"), attribute.style("display", "none")], [])
    _ ->
      html.div([attribute.id("error-container")], [
        html.span([attribute.class("error")], [element.text(error)]),
      ])
  }
}

/// Render the todo list
fn render_todo_list(todos: List(shared.Todo)) -> Element(Msg) {
  html.ul([attribute.id("todo-list")], list.map(todos, render_todo_item))
}

/// Render a single todo item
fn render_todo_item(item: shared.Todo) -> Element(Msg) {
  html.li([attribute.attribute("data-id", item.id)], [
    html.span([attribute.class("title")], [element.text(item.title)]),
    html.span([attribute.class("description")], [element.text(item.description)]),
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(item.completed),
    ]),
    html.button([attribute.class("delete")], [element.text("Delete")]),
  ])
}
