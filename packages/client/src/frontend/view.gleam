import frontend/model.{type Model, FormReady, SubmitError, SubmitSuccess, Submitting}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    rating_form(model),
  ])
}

fn rating_form(model: Model) -> Element(Msg) {
  case model.rating_page {
    Submitting -> loading_view()
    SubmitSuccess -> success_view()
    FormReady -> form_view(model, "")
    SubmitError(err) -> form_view(model, err)
  }
}

fn loading_view() -> Element(Msg) {
  html.div([attribute.class("rating-form rating-loading")], [
    html.p([], [element.text("Submitting your rating...")]),
  ])
}

fn success_view() -> Element(Msg) {
  html.div([attribute.class("rating-form rating-success")], [
    html.p([], [element.text("Rating submitted!")]),
    html.button([event.on_click(msg.ResetRating), attribute.class("btn")], [
      element.text("Rate another"),
    ]),
  ])
}

fn form_view(model: Model, error: String) -> Element(Msg) {
  html.div([attribute.class("rating-form")], [
    html.h2([], [element.text("Rate this boba")]),
    case error {
      "" -> element.none()
      e ->
        html.div([attribute.class("rating-error")], [element.text(e)])
    },
    rating_scale("Sweetness", msg.Sweetness, model.rating.sweetness),
    rating_scale("Boba Texture", msg.BobaTexture, model.rating.boba_texture),
    rating_scale("Tea Strength", msg.TeaStrength, model.rating.tea_strength),
    rating_scale("Overall", msg.Overall, model.rating.overall),
    html.button(
      [event.on_click(msg.SubmitRating), attribute.class("btn btn-submit")],
      [element.text("Submit Rating")],
    ),
  ])
}

fn rating_scale(
  label: String,
  category: msg.RatingCategory,
  current: Int,
) -> Element(Msg) {
  html.div([attribute.class("rating-scale")], [
    html.label([], [element.text(label)]),
    html.div(
      [attribute.class("rating-buttons")],
      list.map([1, 2, 3, 4, 5], fn(v) {
        let active = case v <= current {
          True -> " active"
          False -> ""
        }
        html.button(
          [
            event.on_click(msg.SetRating(category, v)),
            attribute.class("rating-dot" <> active),
            attribute.attribute("aria-label", label <> " " <> int.to_string(v)),
          ],
          [element.text(int.to_string(v))],
        )
      }),
    ),
  ])
}
