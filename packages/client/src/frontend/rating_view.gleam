/// DrinkRatingModal view component

import frontend/rating_model.{type RatingForm}
import frontend/rating_msg.{type RatingMsg}
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

fn slider_label(value: Int) -> String {
  case value {
    1 -> "Very Low"
    2 -> "Low"
    3 -> "Medium"
    4 -> "High"
    5 -> "Very High"
    _ -> "Medium"
  }
}

// Hardcoded list of star numbers since list.range is not available
const star_numbers = [1, 2, 3, 4, 5]

fn star_rating(
  current_score: Int,
  on_change: fn(Int) -> RatingMsg,
  disabled: Bool,
) -> Element(RatingMsg) {
  html.div([attribute.class("star-rating")], [
    html.div([attribute.class("stars-container")], {
      star_numbers
      |> list.map(fn(star_num) {
        let is_filled = star_num <= current_score
        let star_class = case is_filled {
          True -> "star filled"
          False -> "star empty"
        }

        html.button(
          [
            attribute.class(star_class),
            attribute.type_("button"),
            attribute.disabled(disabled),
            event.on_click(on_change(star_num)),
            attribute.attribute("aria-label", "Rate " <> int.to_string(star_num) <> " stars"),
          ],
          [element.text(case is_filled { True -> "★" False -> "☆" })],
        )
      })
    }),
    html.span([attribute.class("rating-label")], [
      element.text(case current_score {
        0 -> "Select a rating"
        1 -> "1 star - Poor"
        2 -> "2 stars - Fair"
        3 -> "3 stars - Good"
        4 -> "4 stars - Very Good"
        5 -> "5 stars - Excellent"
        _ -> ""
      }),
    ]),
  ])
}

fn slider_input(
  label: String,
  value: Int,
  on_change: fn(Int) -> RatingMsg,
  disabled: Bool,
) -> Element(RatingMsg) {
  html.div([attribute.class("slider-input")], [
    html.label([], [
      element.text(label),
      html.span([attribute.class("slider-value")], [
        element.text(int.to_string(value) <> " - " <> slider_label(value)),
      ]),
    ]),
    html.input([
      attribute.type_("range"),
      attribute.min("1"),
      attribute.max("5"),
      attribute.value(int.to_string(value)),
      attribute.disabled(disabled),
      event.on_input(fn(val) {
        case int.parse(val) {
          Ok(num) -> on_change(num)
          Error(_) -> on_change(3)
        }
      }),
    ]),
    html.div([attribute.class("slider-labels")], [
      html.span([], [element.text("1")]),
      html.span([], [element.text("2")]),
      html.span([], [element.text("3")]),
      html.span([], [element.text("4")]),
      html.span([], [element.text("5")]),
    ]),
  ])
}

fn review_textarea(
  value: String,
  on_change: fn(String) -> RatingMsg,
  disabled: Bool,
) -> Element(RatingMsg) {
  html.div([attribute.class("review-textarea")], [
    html.label([], [element.text("Review (Optional)")]),
    html.textarea(
      [
        attribute.placeholder("Share your thoughts about this drink..."),
        attribute.value(value),
        attribute.disabled(disabled),
        attribute.rows(4),
        event.on_input(on_change),
      ],
      "",
    ),
    html.div([attribute.class("char-count")], [
      element.text(int.to_string(string.length(value)) <> " characters"),
    ]),
  ])
}

fn error_message(message: String) -> Element(RatingMsg) {
  html.div([attribute.class("error-message")], [
    html.span([attribute.class("error-icon")], [element.text("⚠")]),
    element.text(message),
  ])
}

fn loading_overlay() -> Element(RatingMsg) {
  html.div([attribute.class("loading-overlay")], [
    html.div([attribute.class("spinner")], []),
    html.p([], [element.text("Submitting your rating...")]),
  ])
}

fn success_state(on_close: RatingMsg) -> Element(RatingMsg) {
  html.div([attribute.class("success-state")], [
    html.div([attribute.class("success-icon")], [element.text("✓")]),
    html.h3([], [element.text("Rating Submitted!")]),
    html.p([], [element.text("Thank you for sharing your feedback.")]),
    html.button(
      [
        attribute.class("close-button"),
        attribute.type_("button"),
        event.on_click(on_close),
      ],
      [element.text("Close")],
    ),
  ])
}

fn empty_state() -> Element(RatingMsg) {
  html.div([attribute.class("empty-state")], [
    html.p([], [element.text("No rating data available. Start by selecting your overall rating above.")]),
  ])
}

fn form_content(
  form: RatingForm,
  disabled: Bool,
) -> Element(RatingMsg) {
  html.div([attribute.class("form-content")], [
    html.div([attribute.class("form-section overall-rating")], [
      html.h3([], [element.text("Overall Rating")]),
      star_rating(
        form.scores.overall,
        rating_msg.RatingOverallChanged,
        disabled,
      ),
    ]),

    case form.scores.overall == 0 {
      True -> empty_state()
      False -> {
        html.div([attribute.class("detailed-ratings")], [
          html.h4([], [element.text("Detailed Ratings")]),
          slider_input(
            "Sweetness",
            form.scores.sweetness,
            rating_msg.RatingSweetnessChanged,
            disabled,
          ),
          slider_input(
            "Boba Texture",
            form.scores.boba_texture,
            rating_msg.RatingBobaTextureChanged,
            disabled,
          ),
          slider_input(
            "Tea Strength",
            form.scores.tea_strength,
            rating_msg.RatingTeaStrengthChanged,
            disabled,
          ),
        ])
      }
    },

    review_textarea(
      form.review_text,
      rating_msg.RatingReviewTextChanged,
      disabled,
    ),
  ])
}

fn form_actions(
  form: RatingForm,
  on_close: RatingMsg,
) -> Element(RatingMsg) {
  let is_submitting = rating_model.is_submitting(form)
  let can_submit = rating_model.can_submit(form)

  html.div([attribute.class("form-actions")], [
    html.button(
      [
        attribute.class("cancel-button"),
        attribute.type_("button"),
        attribute.disabled(is_submitting),
        event.on_click(on_close),
      ],
      [element.text("Cancel")],
    ),
    html.button(
      [
        attribute.class("submit-button"),
        attribute.type_("submit"),
        attribute.disabled(!can_submit || is_submitting),
      ],
      [
        element.text(case is_submitting {
          True -> "Submitting..."
          False -> "Submit Rating"
        }),
      ],
    ),
  ])
}

pub fn drink_rating_modal(
  form: RatingForm,
  drink_name: String,
  on_close: RatingMsg,
) -> Element(RatingMsg) {
  let is_submitting = rating_model.is_submitting(form)

  html.div([attribute.class("modal-overlay")], [
    html.div([attribute.class("modal-container")], [
      html.div([attribute.class("modal-header")], [
        html.h2([], [element.text("Rate Drink")]),
        html.button(
          [
            attribute.class("close-icon"),
            attribute.type_("button"),
            attribute.disabled(is_submitting),
            event.on_click(on_close),
          ],
          [element.text("×")],
        ),
      ]),

      html.div([attribute.class("modal-subtitle")], [
        element.text("How was your "),
        html.strong([], [element.text(drink_name)]),
        element.text("?"),
      ]),

      case form.status {
        rating_model.FormSuccess -> success_state(on_close)
        _ -> {
          html.form(
            [
              attribute.class("rating-form"),
              event.on_submit(fn(_) { rating_msg.RatingSubmitClicked }),
            ],
            [
              case form.status {
                rating_model.FormError(msg) -> error_message(msg)
                _ -> element.text("")
              },
              form_content(form, is_submitting),
              form_actions(form, on_close),
              case is_submitting {
                True -> loading_overlay()
                False -> element.text("")
              },
            ],
          )
        }
      },
    ]),
  ])
}

