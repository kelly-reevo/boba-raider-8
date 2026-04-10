/// Application views

import frontend/components/store_rating_form
import frontend/model.{type Model}
import frontend/msg.{type Msg, Inline, Modal}
import gleam/int
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),

    // Counter section (existing)
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

    // Demo: Button to open rating form
    html.div([attribute.class("demo-section")], [
      html.h2([], [element.text("Store Rating Form Demo")]),
      html.button(
        [event.on_click(msg.RatingFormOpened("store-123", Modal))],
        [element.text("Open Rating Form (Modal)")],
      ),
      html.button(
        [event.on_click(msg.RatingFormOpened("store-123", Inline))],
        [element.text("Show Rating Form (Inline)")],
      ),
    ]),

    // Render rating form if active
    case model.rating_form {
      Some(form_model) -> store_rating_form.view(form_model)
      None -> element.none()
    },
  ])
}
