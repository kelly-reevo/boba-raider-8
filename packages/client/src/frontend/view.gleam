/// View rendering for the todo application

import frontend/model.{type Filter, type Model, Active, All, Completed}
import frontend/msg.{type Msg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Todo}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    render_filter_tabs(model.filter),
    render_todo_list(model),
  ])
}

fn render_filter_tabs(active_filter: Filter) -> Element(Msg) {
  html.div([attribute.class("filter-tabs")], [
    filter_tab_button("all", "All", active_filter == All),
    filter_tab_button("active", "Active", active_filter == Active),
    filter_tab_button("completed", "Completed", active_filter == Completed),
  ])
}

fn filter_tab_button(filter: String, label: String, is_active: Bool) -> Element(Msg) {
  let attrs = case is_active {
    True -> [
      attribute.class("filter-tab active"),
      attribute.data("filter", filter),
      event.on_click(msg.FilterChanged(filter)),
    ]
    False -> [
      attribute.class("filter-tab"),
      attribute.data("filter", filter),
      event.on_click(msg.FilterChanged(filter)),
    ]
  }
  html.button(attrs, [element.text(label)])
}

fn render_todo_list(model: Model) -> Element(Msg) {
  case model.loading {
    True -> html.div([attribute.class("loading")], [element.text("Loading...")])
    False -> {
      case model.todos {
        [] -> render_empty_state(model.filter)
        todos -> html.ul([attribute.id("todo-list")], list.map(todos, render_todo_item))
      }
    }
  }
}

fn render_todo_item(item: Todo) -> Element(Msg) {
  let item_class = case item.completed {
    True -> "todo-item completed"
    False -> "todo-item"
  }
  html.li([attribute.class(item_class)], [
    html.span([attribute.class("todo-title")], [element.text(item.title)]),
  ])
}

fn render_empty_state(filter: Filter) -> Element(Msg) {
  let message = case filter {
    All -> "No todos yet. Add one to get started!"
    Active -> "No active todos. All caught up!"
    Completed -> "No completed todos yet."
  }
  html.div([attribute.id("empty-state")], [element.text(message)])
}
