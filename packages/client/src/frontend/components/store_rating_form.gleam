/// Store rating form component for submitting and managing store ratings.
/// Supports both modal and inline display modes.

import frontend/msg.{type DisplayMode, type Msg, Inline, Modal}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Maximum length for review text
const max_review_length = 1000

/// Form submission state
pub type SubmitState {
  Idle
  Submitting
  SubmitSuccess
  SubmitError(String)
}

/// Store rating form state
pub type StoreRatingFormModel {
  StoreRatingFormModel(
    store_id: String,
    overall_score: Int,
    review_text: String,
    submit_state: SubmitState,
    display_mode: DisplayMode,
    existing_rating_id: Option(String),
  )
}

/// Initialize form for a new rating
pub fn init_new(store_id: String, display_mode: DisplayMode) -> StoreRatingFormModel {
  StoreRatingFormModel(
    store_id: store_id,
    overall_score: 0,
    review_text: "",
    submit_state: Idle,
    display_mode: display_mode,
    existing_rating_id: None,
  )
}

/// Initialize form with existing rating data for editing
pub fn init_edit(
  store_id: String,
  rating_id: String,
  overall_score: Int,
  review_text: String,
  display_mode: DisplayMode,
) -> StoreRatingFormModel {
  StoreRatingFormModel(
    store_id: store_id,
    overall_score: overall_score,
    review_text: review_text,
    submit_state: Idle,
    display_mode: display_mode,
    existing_rating_id: Some(rating_id),
  )
}

/// Check if form has any user input
pub fn has_input(model: StoreRatingFormModel) -> Bool {
  model.overall_score > 0 || !string.is_empty(model.review_text)
}

/// Check if form is valid for submission
pub fn is_valid(model: StoreRatingFormModel) -> Bool {
  model.overall_score > 0 && string.length(model.review_text) <= max_review_length
}

/// Star rating input component
fn star_input(
  current_score: Int,
  star_value: Int,
) -> Element(Msg) {
  let is_filled = star_value <= current_score
  let star_class = case is_filled {
    True -> "star filled"
    False -> "star empty"
  }

  html.span(
    [
      attribute.class(star_class),
      attribute.data("value", int.to_string(star_value)),
      event.on_click(msg.RatingScoreChanged(star_value)),
      attribute.role("button"),
      attribute.attribute("aria-label", "Rate " <> int.to_string(star_value) <> " stars"),
      attribute.attribute("tabindex", "0"),
    ],
    [element.text(case is_filled { True -> "★" False -> "☆" })],
  )
}

/// Render 5-star rating selector
fn star_rating_selector(current_score: Int) -> Element(Msg) {
  html.div(
    [attribute.class("star-rating"), attribute.role("radiogroup"), attribute.attribute("aria-label", "Overall rating")],
    [
      star_input(current_score, 1),
      star_input(current_score, 2),
      star_input(current_score, 3),
      star_input(current_score, 4),
      star_input(current_score, 5),
    ],
  )
}

/// Review text input component
fn review_textarea(model: StoreRatingFormModel) -> Element(Msg) {
  let char_count = string.length(model.review_text)
  let is_at_limit = char_count >= max_review_length
  let count_class = case is_at_limit {
    True -> "char-count at-limit"
    False -> "char-count"
  }

  html.div([attribute.class("review-input-group")], [
    html.label([attribute.for("review-text")], [element.text("Review (optional)")]),
    html.textarea(
      [
        attribute.id("review-text"),
        attribute.class("review-textarea"),
        attribute.placeholder("Share your experience with this store..."),
        attribute.value(model.review_text),
        attribute.attribute("maxlength", int.to_string(max_review_length)),
        attribute.rows(4),
        event.on_input(msg.RatingReviewTextChanged),
        case model.submit_state {
          Submitting -> attribute.disabled(True)
          _ -> attribute.disabled(False)
        },
      ],
      "",
    ),
    html.span([attribute.class(count_class)], [
      element.text(int.to_string(char_count) <> "/" <> int.to_string(max_review_length)),
    ]),
  ])
}

/// Submit button component
fn submit_button(model: StoreRatingFormModel) -> Element(Msg) {
  let button_text = case model.submit_state {
    Submitting -> "Submitting..."
    SubmitSuccess -> "Submitted!"
    _ -> case model.existing_rating_id {
      Some(_) -> "Update Rating"
      None -> "Submit Rating"
    }
  }

  let is_disabled = case model.submit_state {
    Submitting -> True
    _ -> !is_valid(model)
  }

  html.button(
    [
      attribute.class("submit-rating-btn"),
      attribute.type_("submit"),
      attribute.disabled(is_disabled),
    ],
    [element.text(button_text)],
  )
}

/// Delete button (only shown when editing existing rating)
fn delete_button(model: StoreRatingFormModel) -> Element(Msg) {
  case model.existing_rating_id {
    Some(_) -> html.button(
      [
        attribute.class("delete-rating-btn"),
        attribute.type_("button"),
        event.on_click(msg.RatingDeleteClicked),
        attribute.disabled(case model.submit_state { Submitting -> True _ -> False }),
      ],
      [element.text("Delete Rating")],
    )
    None -> element.none()
  }
}

/// Error message display
fn error_message(model: StoreRatingFormModel) -> Element(Msg) {
  case model.submit_state {
    SubmitError(msg) -> html.div([attribute.class("form-error")], [
      html.span([attribute.class("error-icon")], [element.text("⚠")]),
      element.text(msg),
    ])
    _ -> element.none()
  }
}

/// Loading overlay
fn loading_overlay(model: StoreRatingFormModel) -> Element(Msg) {
  case model.submit_state {
    Submitting -> html.div([attribute.class("loading-overlay")], [
      html.div([attribute.class("spinner")], []),
      element.text("Submitting..."),
    ])
    _ -> element.none()
  }
}

/// Success message
fn success_message(model: StoreRatingFormModel) -> Element(Msg) {
  case model.submit_state {
    SubmitSuccess -> html.div([attribute.class("success-message")], [
      html.span([attribute.class("success-icon")], [element.text("✓")]),
      element.text("Rating submitted successfully!"),
    ])
    _ -> element.none()
  }
}

/// Empty state indicator (shown when no score selected yet)
fn empty_state_hint(model: StoreRatingFormModel) -> Element(Msg) {
  case model.overall_score {
    0 -> html.p([attribute.class("empty-hint")], [
      element.text("Click a star to rate this store"),
    ])
    _ -> element.none()
  }
}

/// Main form view
fn form_content(model: StoreRatingFormModel) -> Element(Msg) {
  html.form(
    [
      attribute.class("store-rating-form"),
      event.on_submit(fn(_form_data) { msg.RatingFormSubmitted }),
    ],
    [
      html.h3([attribute.class("form-title")], [
        element.text(case model.existing_rating_id {
          Some(_) -> "Update Your Rating"
          None -> "Rate This Store"
        }),
      ]),
      empty_state_hint(model),
      html.div([attribute.class("rating-field")], [
        html.label([], [element.text("Overall Score *")]),
        star_rating_selector(model.overall_score),
      ]),
      review_textarea(model),
      error_message(model),
      success_message(model),
      html.div([attribute.class("form-actions")], [
        submit_button(model),
        delete_button(model),
      ]),
      loading_overlay(model),
    ],
  )
}

/// Render the store rating form
pub fn view(model: StoreRatingFormModel) -> Element(Msg) {
  case model.display_mode {
    Modal -> html.div([attribute.class("modal-backdrop")], [
      html.div([attribute.class("modal-container")], [
        html.button(
          [attribute.class("modal-close"), event.on_click(msg.RatingFormClosed)],
          [element.text("×")],
        ),
        form_content(model),
      ]),
    ])
    Inline -> html.div([attribute.class("inline-form-container")], [
      form_content(model),
    ])
  }
}
