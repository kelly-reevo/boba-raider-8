/// Main view module

import frontend/model.{type Model, CounterPage, EditStorePage}
import frontend/msg.{type Msg, Increment, Decrement, Reset}
import frontend/pages/edit_store_page
import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{Some}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    render_header(),
    html.main([attribute.class("main-content")], [
      render_page(model),
    ]),
    render_footer(),
  ])
}

fn render_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [element.text("boba-raider-8")]),
    html.nav([], [
      html.a([attribute.href("/")], [element.text("Home")]),
      html.a([attribute.href("/stores")], [element.text("Stores")]),
    ]),
  ])
}

fn render_footer() -> Element(Msg) {
  html.footer([attribute.class("app-footer")], [
    element.text("boba-raider-8 2024"),
  ])
}

fn render_page(model: Model) -> Element(Msg) {
  case model.page {
    CounterPage(count, _error) -> counter_view(count)
    EditStorePage(state) -> edit_store_page.view(state, model.current_user)
    _ -> html.div([], [element.text("Page not found")])
  }
}

fn counter_view(count: Int) -> Element(Msg) {
  html.div([attribute.class("counter-page")], [
    html.h2([], [element.text("Counter")]),
    html.div([attribute.class("counter")], [
      html.button([event.on_click(Decrement)], [element.text("-")]),
      html.span([attribute.class("count")], [
        element.text(int.to_string(count)),
      ]),
      html.button([event.on_click(Increment)], [element.text("+")]),
    ]),
    html.button([event.on_click(Reset), attribute.class("reset")], [
      element.text("Reset"),
    ]),
  ])
}
