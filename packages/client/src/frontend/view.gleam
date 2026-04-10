/// Main application view

import frontend/create_drink_form
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Main app content (original counter demo)
    html.h1([], [element.text("boba-raider-8")]),
    html.div([attribute.class("counter")], [
      html.button([event.on_click(msg.Decrement)], [element.text("-")]),
      html.span([attribute.class("count")], [
        element.text("Count: " <> int.to_string(model.count)),
      ]),
      html.button([event.on_click(msg.Increment)], [element.text("+")]),
    ]),
    html.button([event.on_click(msg.Reset), attribute.class("reset")], [
      element.text("Reset"),
    ]),

    // Demo: Store detail section with create drink button
    html.div([attribute.class("store-detail-demo")], [
      html.h2([], [element.text("Store Detail Page Demo")]),
      html.p([], [element.text("Example of how the create button appears on a store detail page: ")]),
      // Example: Create drink button (would be called from store detail page)
      create_drink_form.render_create_button("store-123"),
    ]),

    // The create drink form modal (renders when show_create_form is true)
    create_drink_form.view(model),
  ])
}
