/// Main view for boba-raider-8 application

import frontend/components.{drink_detail_view, rating_form_view, store_list_view}
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("Boba Raider")]),
    html.div([attribute.class("main-content")], [
      html.div([attribute.class("store-section")], [
        store_list_view(model),
      ]),
      html.div([attribute.class("detail-section")], [
        drink_detail_view(model),
      ]),
      html.div([attribute.class("rating-section")], [
        html.h2([], [element.text("Rate a Drink")]),
        rating_form_view(model),
      ]),
    ]),
  ])
}
