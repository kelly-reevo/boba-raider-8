/// Loading state components: SkeletonStoreCard, SkeletonDrinkCard, LoadingSpinner

import frontend/msg.{type Msg}
import frontend/model.{type Model, Model}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import gleam/option.{None}

/// Creates a skeleton store card with accessibility attributes
pub fn skeleton_store_card(model: Model) -> Element(Msg) {
  let motion_class = case model.prefers_reduced_motion {
    True -> "skeleton-store-card static-placeholder reduced-motion"
    False -> "skeleton-store-card"
  }

  html.div(
    [
      attribute.class(motion_class),
      attribute.role("status"),
      attribute.attribute("aria-label", "Loading store information"),
    ],
    [
      skeleton_image(model),
      skeleton_text(model, "store-name", 1),
      skeleton_rating(model),
    ],
  )
}

/// Creates a skeleton drink card with accessibility attributes
pub fn skeleton_drink_card(model: Model) -> Element(Msg) {
  let motion_class = case model.prefers_reduced_motion {
    True -> "skeleton-drink-card static-placeholder reduced-motion"
    False -> "skeleton-drink-card"
  }

  html.div(
    [
      attribute.class(motion_class),
      attribute.role("status"),
      attribute.attribute("aria-live", "polite"),
      attribute.attribute("aria-label", "Loading drink details"),
    ],
    [
      html.div([attribute.class("skeleton-drink-image")], [skeleton_image(model)]),
      html.div([attribute.class("skeleton-drink-name")], [skeleton_text(model, "drink-name", 1)]),
      html.div([attribute.class("skeleton-drink-description")], [skeleton_text(model, "drink-desc", 2)]),
      html.div([attribute.class("skeleton-rating-bars")], [
        skeleton_rating_axis(model, "sweetness"),
        skeleton_rating_axis(model, "boba-texture"),
        skeleton_rating_axis(model, "tea-strength"),
      ]),
    ],
  )
}

/// Creates a loading spinner with accessibility attributes
pub fn loading_spinner(model: Model) -> Element(Msg) {
  let spinner_content = case model.prefers_reduced_motion {
    True -> html.span([attribute.class("static-loading-indicator")], [element.text("Loading...")])
    False -> html.span([attribute.class("spinner-animation")], [])
  }

  html.span(
    [
      attribute.class("loading-spinner"),
      attribute.role("status"),
      attribute.attribute("aria-label", "Loading"),
      attribute.attribute("aria-hidden", "false"),
    ],
    [spinner_content],
  )
}

/// Creates a submit button with loading state
pub fn submit_button(model: Model, submitting: Bool) -> Element(Msg) {
  let button_text = case submitting {
    True -> "Submitting..."
    False -> "Submit Rating"
  }

  let button_attrs = case submitting {
    True -> [
      attribute.class("submit-rating-button"),
      attribute.disabled(True),
      attribute.attribute("aria-disabled", "true"),
    ]
    False -> [
      attribute.class("submit-rating-button"),
    ]
  }

  let button_children = case submitting {
    True -> [loading_spinner(model), element.text(button_text)]
    False -> [element.text(button_text)]
  }

  html.button(button_attrs, button_children)
}

/// Helper: Create a skeleton image placeholder
fn skeleton_image(model: Model) -> Element(Msg) {
  let class = case model.prefers_reduced_motion {
    True -> "skeleton-image static-placeholder reduced-motion"
    False -> "skeleton-image"
  }
  html.div([attribute.class(class)], [])
}

/// Helper: Create skeleton text lines
fn skeleton_text(model: Model, suffix: String, lines: Int) -> Element(Msg) {
  let class = case model.prefers_reduced_motion {
    True -> "skeleton-text static-placeholder reduced-motion"
    False -> "skeleton-text"
  }

  let line_elements = case lines {
    1 -> [html.div([attribute.class(class <> " " <> suffix)], [])]
    2 -> [
      html.div([attribute.class(class <> " " <> suffix)], []),
      html.div([attribute.class(class <> " " <> suffix)], []),
    ]
    _ -> [html.div([attribute.class(class <> " " <> suffix)], [])]
  }

  html.div([attribute.class("skeleton-text-container")], line_elements)
}

/// Helper: Create a skeleton rating placeholder
fn skeleton_rating(model: Model) -> Element(Msg) {
  let class = case model.prefers_reduced_motion {
    True -> "skeleton-rating static-placeholder reduced-motion"
    False -> "skeleton-rating"
  }
  html.div([attribute.class(class)], [])
}

/// Helper: Create a skeleton rating axis placeholder
fn skeleton_rating_axis(model: Model, axis_name: String) -> Element(Msg) {
  let base_class = case model.prefers_reduced_motion {
    True -> "static-rating-placeholder reduced-motion"
    False -> "skeleton-rating-bar"
  }

  html.div(
    [
      attribute.class("skeleton-" <> axis_name <> "-rating " <> base_class),
    ],
    [html.div([attribute.class("skeleton-rating-bar")], [])],
  )
}

// ============================================================================
// Test API Functions - Simple versions for testing
// ============================================================================

/// Creates a skeleton store card with default settings (no reduced motion)
pub fn create_skeleton_store_card() -> Element(Msg) {
  let default_model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: False,
  )
  skeleton_store_card(default_model)
}

/// Creates a skeleton drink card with default settings (no reduced motion)
pub fn create_skeleton_drink_card() -> Element(Msg) {
  let default_model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: False,
  )
  skeleton_drink_card(default_model)
}

/// Creates a loading spinner with default settings (no reduced motion)
pub fn create_loading_spinner() -> Element(Msg) {
  let default_model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: False,
  )
  loading_spinner(default_model)
}

/// Creates a skeleton store card respecting the reduced motion preference
pub fn create_skeleton_store_card_respecting_motion(
  prefers_reduced_motion: Bool,
) -> Element(Msg) {
  let model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: prefers_reduced_motion,
  )
  skeleton_store_card(model)
}

/// Creates a skeleton drink card respecting the reduced motion preference
pub fn create_skeleton_drink_card_respecting_motion(
  prefers_reduced_motion: Bool,
) -> Element(Msg) {
  let model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: prefers_reduced_motion,
  )
  skeleton_drink_card(model)
}

/// Creates a loading spinner respecting the reduced motion preference
pub fn create_loading_spinner_respecting_motion(
  prefers_reduced_motion: Bool,
) -> Element(Msg) {
  let model = Model(
    stores_loading: False,
    stores: [],
    stores_error: None,
    drink_loading: False,
    drink: None,
    drink_ratings: [],
    drink_error: None,
    rating_sweetness: 0,
    rating_boba_texture: 0,
    rating_tea_strength: 0,
    rating_submitting: False,
    rating_submit_error: None,
    prefers_reduced_motion: prefers_reduced_motion,
  )
  loading_spinner(model)
}
