/// Drink Detail View - Page component for drink details with ratings

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, Some, None}
import gleam/string
import frontend/drink_detail_model.{
  type DrinkDetailModel, type DrinkDetail, type RatingAggregates, type Review,
  type DrinkDetailState, LoadingDrink, LoadingDetails, Populated, EmptyReviews, DrinkNotFound, LoadError
}
import frontend/drink_detail_msg.{type DrinkDetailMsg}
import lustre/attribute
import lustre/element.{type Element, text as element_text}
import lustre/element/html
import lustre/event

/// Main view function for drink detail page
pub fn view(model: DrinkDetailModel) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-page")], [
    render_state(model.state, model.drink_id)
  ])
}

/// Render the appropriate state
fn render_state(state: DrinkDetailState, drink_id: String) -> Element(DrinkDetailMsg) {
  case state {
    LoadingDrink -> loading_view()
    LoadingDetails(drink:) -> loading_details_view(drink)
    Populated(drink:, aggregates:, reviews:) -> populated_view(drink, aggregates, reviews)
    EmptyReviews(drink:, aggregates:) -> empty_reviews_view(drink, aggregates)
    DrinkNotFound(drink_id:) -> not_found_view(drink_id)
    LoadError(message:) -> error_view(message)
  }
}

// ---------------------------------------------------------------------------
// Loading States
// ---------------------------------------------------------------------------

/// Initial loading state - drink not yet loaded
fn loading_view() -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-loading")], [
    html.div([attribute.class("loading-spinner")], []),
    html.p([], [element_text("Loading drink details...")])
  ])
}

/// Loading state when drink is loaded but details are fetching
fn loading_details_view(drink: DrinkDetail) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-loading-details")], [
    drink_header(drink, show_back_button: True),
    html.div([attribute.class("details-loading")], [
      html.div([attribute.class("loading-spinner-small")], []),
      html.p([], [element_text("Loading ratings and reviews...")])
    ])
  ])
}

// ---------------------------------------------------------------------------
// Error States
// ---------------------------------------------------------------------------

/// 404 Not Found state
fn not_found_view(drink_id: String) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-not-found")], [
    html.h2([], [element_text("Drink Not Found")]),
    html.p([], [
      element_text("We couldn't find a drink with ID: " <> drink_id)
    ]),
    html.button(
      [event.on_click(drink_detail_msg.RetryLoad)],
      [element_text("Try Again")]
    )
  ])
}

/// Generic error state
fn error_view(message: String) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-error")], [
    html.h2([], [element_text("Error Loading Drink")]),
    html.p([attribute.class("error-message")], [element_text(message)]),
    html.button(
      [event.on_click(drink_detail_msg.RetryLoad)],
      [element_text("Retry")]
    )
  ])
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

/// State when drink exists but has no reviews
fn empty_reviews_view(
  drink: DrinkDetail,
  aggregates: RatingAggregates
) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-empty")], [
    drink_header(drink, show_back_button: True),
    html.div([attribute.class("drink-info-section")], [
      drink_info_panel(drink)
    ]),
    html.div([attribute.class("ratings-section")], [
      html.h3([], [element_text("Ratings")]),
      html.div([attribute.class("no-ratings-yet")], [
        html.p([], [element_text("No ratings yet. Be the first to rate this drink!")]),
        add_rating_button(drink.id)
      ])
    ]),
    html.div([attribute.class("reviews-section")], [
      html.h3([], [element_text("Reviews")]),
      html.p([attribute.class("no-reviews")], [element_text("No reviews yet.")])
    ])
  ])
}

// ---------------------------------------------------------------------------
// Populated State
// ---------------------------------------------------------------------------

/// Full populated state with all data
fn populated_view(
  drink: DrinkDetail,
  aggregates: RatingAggregates,
  reviews: List(Review)
) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-detail-populated")], [
    drink_header(drink, show_back_button: True),
    html.div([attribute.class("drink-info-section")], [
      drink_info_panel(drink)
    ]),
    html.div([attribute.class("ratings-section")], [
      html.h3([], [element_text("Ratings")]),
      rating_breakdown(aggregates),
      add_rating_button(drink.id)
    ]),
    html.div([attribute.class("reviews-section")], [
      html.h3([], [
        element_text("Reviews (" <> int.to_string(aggregates.count) <> ")")
      ]),
      review_list(reviews)
    ])
  ])
}

// ---------------------------------------------------------------------------
// Component: DrinkHeader
// ---------------------------------------------------------------------------

/// Header component with drink name and back button
fn drink_header(drink: DrinkDetail, show_back_button back: Bool) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-header")], [
    html.div([attribute.class("header-content")], [
      case back {
        True -> html.button(
          [
            attribute.class("back-button"),
            event.on_click(drink_detail_msg.BackToStoreClicked(drink.store_id))
          ],
          [element_text("← Back")]
        )
        False -> element.none()
      },
      html.h1([attribute.class("drink-name")], [element_text(drink.name)])
    ]),
    html.div([attribute.class("drink-meta")], [
      case drink.base_tea_type {
        Some(tea_type) -> html.span(
          [attribute.class("tea-type-badge")],
          [element_text(tea_type)]
        )
        None -> element.none()
      }
    ])
  ])
}

/// Drink info panel with description and price
fn drink_info_panel(drink: DrinkDetail) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("drink-info-panel")], [
    case drink.description {
      Some(desc) -> html.p(
        [attribute.class("drink-description")],
        [element_text(desc)]
      )
      None -> element.none()
    },
    case drink.price {
      Some(price) -> html.div(
        [attribute.class("drink-price")],
        [element_text(format_price(price))]
      )
      None -> element.none()
    }
  ])
}

/// Format price as currency string
fn format_price(price: Float) -> String {
  "$" <> float.to_string(price)
}

// ---------------------------------------------------------------------------
// Component: RatingBreakdown
// ---------------------------------------------------------------------------

/// Rating breakdown with all categories
fn rating_breakdown(aggregates: RatingAggregates) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("rating-breakdown")], [
    html.div([attribute.class("overall-rating")], [
      html.span([attribute.class("rating-label")], [element_text("Overall")]),
      html.span([attribute.class("rating-value")], [
        element_text(format_optional_float(aggregates.overall_rating))
      ]),
      html.span([attribute.class("rating-count")], [
        element_text("(" <> int.to_string(aggregates.count) <> " ratings)")
      ])
    ]),
    html.div([attribute.class("rating-categories")], [
      rating_bar("Sweetness", aggregates.sweetness),
      rating_bar("Boba Texture", aggregates.boba_texture),
      rating_bar("Tea Strength", aggregates.tea_strength)
    ])
  ])
}

/// Individual rating bar for a category
fn rating_bar(label: String, value: Option(Float)) -> Element(DrinkDetailMsg) {
  let rating_value = case value {
    Some(v) -> v
    None -> 0.0
  }
  let percentage = rating_value /. 5.0 *. 100.0

  html.div([attribute.class("rating-bar")], [
    html.span([attribute.class("rating-bar-label")], [element_text(label)]),
    html.div([attribute.class("rating-bar-track")], [
      html.div(
        [
          attribute.class("rating-bar-fill"),
          attribute.style("width", float.to_string(percentage) <> "%")
        ],
        []
      )
    ]),
    html.span([attribute.class("rating-bar-value")], [
      element_text(format_optional_float(value) <> "/5")
    ])
  ])
}

/// Format optional float for display
fn format_optional_float(value: Option(Float)) -> String {
  case value {
    Some(f) -> float.to_string(f)
    None -> "--"
  }
}

// ---------------------------------------------------------------------------
// Component: AddRatingButton
// ---------------------------------------------------------------------------

/// Button to add a new rating
fn add_rating_button(drink_id: String) -> Element(DrinkDetailMsg) {
  html.button(
    [
      attribute.class("add-rating-button"),
      event.on_click(drink_detail_msg.AddRatingClicked(drink_id))
    ],
    [element_text("Add Your Rating")]
  )
}

// ---------------------------------------------------------------------------
// Component: ReviewList
// ---------------------------------------------------------------------------

/// List of individual reviews
fn review_list(reviews: List(Review)) -> Element(DrinkDetailMsg) {
  case reviews {
    [] -> html.p([attribute.class("no-reviews")], [element_text("No reviews yet.")])
    _ -> html.div(
      [attribute.class("review-list")],
      list.map(reviews, review_item)
    )
  }
}

/// Individual review item
fn review_item(review: Review) -> Element(DrinkDetailMsg) {
  html.div([attribute.class("review-item")], [
    html.div([attribute.class("review-header")], [
      html.span([attribute.class("reviewer-name")], [
        element_text(review.reviewer_name)
      ]),
      html.span([attribute.class("review-date")], [
        element_text(format_date(review.created_at))
      ])
    ]),
    html.div([attribute.class("review-ratings")], [
      html.span([attribute.class("overall-stars")], [
        element_text(render_stars(review.overall_rating))
      ]),
      html.span([attribute.class("category-ratings")], [
        element_text(
          "Sweetness: " <> int.to_string(review.sweetness) <> "/5 | " <>
          "Boba: " <> int.to_string(review.boba_texture) <> "/5 | " <>
          "Tea: " <> int.to_string(review.tea_strength) <> "/5"
        )
      ])
    ]),
    case review.review_text {
      Some(text) -> html.p([attribute.class("review-text")], [element_text(text)])
      None -> element.none()
    }
  ])
}

/// Render stars for a rating (1-5)
fn render_stars(rating: Int) -> String {
  let filled = string.repeat("★", rating)
  let empty = string.repeat("☆", 5 - rating)
  filled <> empty
}

/// Simple date formatter (shows first 10 chars as YYYY-MM-DD)
fn format_date(date_string: String) -> String {
  case string.length(date_string) >= 10 {
    True -> string.slice(date_string, 0, 10)
    False -> date_string
  }
}

