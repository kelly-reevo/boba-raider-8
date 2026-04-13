import frontend/model.{type Model, type Todo, Model, Loading, Idle}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app"), attribute.attribute("data-testid", "app-container")], [
    html.h1([], [element.text("boba-raider-8")]),
    render_error_banner(model.error),
    render_todo_form(model),
    render_todo_list_section(model),
  ])
}

// Render error banner when there's an error
fn render_error_banner(error: String) -> Element(Msg) {
  case error {
    "" -> html.div([], [])
    _ ->
      html.div(
        [attribute.class("error-banner"), attribute.attribute("data-testid", "error-banner")],
        [element.text(error)],
      )
  }
}

// Render the todo form with loading states
fn render_todo_form(model: Model) -> Element(Msg) {
  let is_submitting = case model.form_loading {
    Loading -> True
    _ -> False
  }

  let submit_btn_content = case is_submitting {
    True -> html.span([attribute.class("spinner"), attribute.attribute("data-testid", "btn-spinner")], [element.text("Loading...")])
    False -> element.text("Add Todo")
  }

  let submit_btn_attrs = [
    attribute.type_("submit"),
    attribute.class("submit-btn"),
    attribute.attribute("data-testid", "submit-btn"),
  ]
  // Disable button during submission
  let submit_btn_attrs = case is_submitting {
    True -> [attribute.disabled(True), ..submit_btn_attrs]
    False -> submit_btn_attrs
  }

  html.form(
    [
      attribute.class("todo-form"),
      attribute.attribute("data-testid", "todo-form"),
      event.on_submit(fn(_) { msg.SubmitTodoRequest }),
    ],
    [
      html.input([
        attribute.type_("text"),
        attribute.name("title"),
        attribute.placeholder("Todo title"),
        attribute.class("title-input"),
        attribute.attribute("data-testid", "title-input"),
        attribute.value(model.title_input),
        event.on_input(msg.TitleInputChanged),
        // Disable input during submission
        case is_submitting {
          True -> attribute.disabled(True)
          False -> attribute.none()
        },
      ]),
      html.textarea(
        [
          attribute.name("description"),
          attribute.placeholder("Description (optional)"),
          attribute.class("description-input"),
          attribute.attribute("data-testid", "description-input"),
          attribute.value(model.description_input),
          event.on_input(msg.DescriptionInputChanged),
          // Disable textarea during submission
          case is_submitting {
            True -> attribute.disabled(True)
            False -> attribute.none()
          },
        ],
        "",
      ),
      html.button(submit_btn_attrs, [submit_btn_content]),
    ],
  )
}

// Render the todo list section with loading indicator
fn render_todo_list_section(model: Model) -> Element(Msg) {
  let is_loading = case model.list_loading {
    Loading -> True
    _ -> False
  }

  let loading_indicator = case is_loading {
    True ->
      html.div(
        [
          attribute.class("loading-indicator"),
          attribute.attribute("data-testid", "loading-indicator"),
        ],
        [
          html.span([attribute.class("spinner")], []),
          element.text("Loading..."),
        ],
      )
    False ->
      // Hidden loading indicator (for test compatibility)
      html.div(
        [
          attribute.class("loading-indicator"),
          attribute.attribute("data-testid", "loading-indicator"),
          attribute.style("display", "none"),
        ],
        [],
      )
  }

  let list_content = case is_loading, model.todos {
    // Show loading state
    True, _ -> [loading_indicator]

    // Show empty state when not loading and no todos
    False, [] -> [loading_indicator, render_empty_state()]

    // Show todo list when not loading and has todos
    False, todos -> [loading_indicator, render_todo_list(model, todos)]
  }

  html.div(
    [
      attribute.class("todo-list-container"),
      attribute.attribute("data-testid", "todo-list-container"),
    ],
    list_content,
  )
}

// Render empty state when no todos
fn render_empty_state() -> Element(Msg) {
  html.div(
    [attribute.class("empty-state"), attribute.attribute("data-testid", "empty-state")],
    [element.text("No todos yet. Add one above!")],
  )
}

// Render the todo list
fn render_todo_list(model: Model, todos: List(Todo)) -> Element(Msg) {
  html.ul(
    [attribute.class("todo-list"), attribute.attribute("data-testid", "todo-list")],
    list.map(todos, fn(item) { render_todo_item(model, item) }),
  )
}

// Check if a specific todo is being operated on
fn is_todo_loading(model: Model, item_id: String) -> Bool {
  case dict.get(model.todo_loading, item_id) {
    Ok(Loading) -> True
    _ -> False
  }
}

// Render a single todo item
fn render_todo_item(model: Model, item: Todo) -> Element(Msg) {
  let is_item_loading = is_todo_loading(model, item.id)
  let is_any_operation_loading = case model.form_loading, model.list_loading {
    Loading, _ -> True
    _, Loading -> True
    _, _ -> False
  }

  // Disable checkbox during any loading operation on this item
  let checkbox_attrs = [
    attribute.type_("checkbox"),
    attribute.class("todo-checkbox"),
    attribute.attribute("data-testid", "todo-checkbox-" <> item.id),
    attribute.checked(item.completed),
    event.on_check(fn(checked) { msg.ToggleTodoRequest(item.id, checked) }),
  ]
  let checkbox_attrs = case is_item_loading || is_any_operation_loading {
    True -> [attribute.disabled(True), ..checkbox_attrs]
    False -> checkbox_attrs
  }

  // Disable delete button during any loading operation on this item
  let delete_btn_attrs = [
    attribute.class("delete-btn"),
    attribute.attribute("data-testid", "delete-btn-" <> item.id),
    event.on_click(msg.DeleteTodoRequest(item.id)),
  ]
  let delete_btn_attrs = case is_item_loading || is_any_operation_loading {
    True -> [attribute.disabled(True), ..delete_btn_attrs]
    False -> delete_btn_attrs
  }

  // Show loading overlay when this specific item is loading
  let loading_overlay = case is_item_loading {
    True ->
      html.span(
        [attribute.class("item-loading-indicator")],
        [element.text("...")],
      )
    False -> element.text("")
  }

  html.li(
    [
      attribute.class(case item.completed {
        True -> "todo-item completed"
        False -> "todo-item"
      }),
      attribute.attribute("data-testid", "todo-item-" <> item.id),
    ],
    [
      html.input(checkbox_attrs),
      html.span(
        [attribute.class("todo-title")],
        [element.text(item.title)],
      ),
      html.button(delete_btn_attrs, [element.text("Delete")]),
      loading_overlay,
    ],
  )
}

import gleam/dict
