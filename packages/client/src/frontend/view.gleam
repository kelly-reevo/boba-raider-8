import gleam/float
import gleam/int
import gleam/list
import frontend/model.{type Model, type RatingsState, RatingsError, RatingsLoaded, RatingsLoading}
import frontend/msg.{type Msg}
import shared.{type RatingDistribution, type RatingsSummary, type Review}
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
    view_ratings(model.ratings),
  ])
}

fn view_ratings(state: RatingsState) -> Element(Msg) {
  html.section([attribute.class("ratings")], [
    html.h2([], [element.text("Ratings & Reviews")]),
    case state {
      RatingsLoading -> view_ratings_loading()
      RatingsError(message) -> view_ratings_error(message)
      RatingsLoaded(summary) -> view_ratings_loaded(summary)
    },
  ])
}

fn view_ratings_loading() -> Element(Msg) {
  html.div([attribute.class("ratings-loading")], [
    html.p([], [element.text("Loading ratings...")]),
  ])
}

fn view_ratings_error(message: String) -> Element(Msg) {
  html.div([attribute.class("ratings-error")], [
    html.p([attribute.class("error-message")], [
      element.text("Failed to load ratings: " <> message),
    ]),
  ])
}

fn view_ratings_loaded(summary: RatingsSummary) -> Element(Msg) {
  case summary.total_count {
    0 -> view_ratings_empty()
    _ -> view_ratings_populated(summary)
  }
}

fn view_ratings_empty() -> Element(Msg) {
  html.div([attribute.class("ratings-empty")], [
    html.p([], [element.text("No ratings yet. Be the first to leave a review!")]),
  ])
}

fn view_ratings_populated(summary: RatingsSummary) -> Element(Msg) {
  html.div([attribute.class("ratings-content")], [
    view_rating_overview(summary.average, summary.total_count),
    view_star_breakdown(summary.distribution, summary.total_count),
    view_reviews_list(summary.reviews),
  ])
}

fn view_rating_overview(average: Float, total_count: Int) -> Element(Msg) {
  html.div([attribute.class("rating-overview")], [
    html.span([attribute.class("rating-average")], [
      element.text(format_rating(average)),
    ]),
    html.span([attribute.class("rating-stars")], [
      element.text(stars_display(average)),
    ]),
    html.span([attribute.class("rating-count")], [
      element.text(int.to_string(total_count) <> " reviews"),
    ]),
  ])
}

fn view_star_breakdown(
  dist: RatingDistribution,
  total: Int,
) -> Element(Msg) {
  html.div([attribute.class("star-breakdown")], [
    view_star_bar(5, dist.five, total),
    view_star_bar(4, dist.four, total),
    view_star_bar(3, dist.three, total),
    view_star_bar(2, dist.two, total),
    view_star_bar(1, dist.one, total),
  ])
}

fn view_star_bar(star: Int, count: Int, total: Int) -> Element(Msg) {
  let pct = case total {
    0 -> 0
    _ -> { count * 100 } / total
  }
  html.div([attribute.class("star-bar")], [
    html.span([attribute.class("star-label")], [
      element.text(int.to_string(star) <> " star"),
    ]),
    html.div([attribute.class("star-bar-track")], [
      html.div(
        [
          attribute.class("star-bar-fill"),
          attribute.style("width", int.to_string(pct) <> "%"),
        ],
        [],
      ),
    ]),
    html.span([attribute.class("star-bar-count")], [
      element.text(int.to_string(count)),
    ]),
  ])
}

fn view_reviews_list(reviews: List(Review)) -> Element(Msg) {
  html.div([attribute.class("reviews-list")], [
    html.h3([], [element.text("Reviews")]),
    html.div(
      [],
      list.map(reviews, view_review),
    ),
  ])
}

fn view_review(review: Review) -> Element(Msg) {
  html.div([attribute.class("review")], [
    html.div([attribute.class("review-header")], [
      html.span([attribute.class("review-author")], [
        element.text(review.author),
      ]),
      html.span([attribute.class("review-rating")], [
        element.text(stars_display(int.to_float(review.rating))),
      ]),
      html.span([attribute.class("review-date")], [
        element.text(review.created_at),
      ]),
    ]),
    html.p([attribute.class("review-text")], [element.text(review.text)]),
  ])
}

fn stars_display(rating: Float) -> String {
  let full = float.truncate(rating)
  let has_half = { rating -. int.to_float(full) } >=. 0.5
  let full_stars = string_repeat("★", full)
  let half_star = case has_half {
    True -> "½"
    False -> ""
  }
  let empty_count = case has_half {
    True -> 5 - full - 1
    False -> 5 - full
  }
  let empty_stars = string_repeat("☆", empty_count)
  full_stars <> half_star <> empty_stars
}

fn string_repeat(s: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> s <> string_repeat(s, n - 1)
  }
}

fn format_rating(rating: Float) -> String {
  let whole = float.truncate(rating)
  let frac = float.truncate({ rating -. int.to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(frac)
}
