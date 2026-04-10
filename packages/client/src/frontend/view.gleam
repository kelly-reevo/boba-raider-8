import gleam/int
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import frontend/rating_msg
import frontend/rating_view
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
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

    // Demo button to open rating modal
    html.button(
      [
        event.on_click(msg.OpenRatingModal("drink-123", "Classic Milk Tea")),
        attribute.class("open-rating-button"),
      ],
      [element.text("Rate Drink (Demo)")],
    ),

    // Rating modal (conditionally rendered)
    case model.rating_modal {
      Some(form) ->
        rating_view.drink_rating_modal(
          form,
          model.selected_drink_name,
          rating_msg.RatingModalClosed,
        )
        |> element.map(msg.RatingFormMsg)
      None -> element.text("")
    },
  ])
}
