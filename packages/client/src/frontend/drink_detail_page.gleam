import frontend/model.{type DrinkDetailState, DrinkDetailLoading, DrinkDetailError, DrinkDetailEmpty, DrinkDetailPopulated}
import frontend/msg.{type Msg}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import shared.{type Drink, type Rating, type RatingBreakdown}

/// Main drink detail page component
pub fn drink_detail_page(state: DrinkDetailState) -> Element(Msg) {
  case state {
    DrinkDetailLoading -> loading_view()
    DrinkDetailError(msg) -> error_view(msg)
    DrinkDetailEmpty -> empty_view()
    DrinkDetailPopulated(drink, user_rating, other_ratings) ->
      populated_view(drink, user_rating, other_ratings)
  }
}

// State views

fn loading_view() -> Element(Msg) {
  html.div([attribute.class("drink-detail loading")], [
    html.div([attribute.class("loading-spinner")], []),
    html.p([], [text("Loading drink details...")]),
  ])
}

fn error_view(msg: String) -> Element(Msg) {
  html.div([attribute.class("drink-detail error")], [
    html.div([attribute.class("error-icon")], [text("⚠")]),
    html.h2([], [text("Error loading drink")]),
    html.p([], [text(msg)]),
  ])
}

fn empty_view() -> Element(Msg) {
  html.div([attribute.class("drink-detail empty")], [
    html.div([attribute.class("empty-icon")], [text("🥤")]),
    html.h2([], [text("No drink found")]),
    html.p([], [text("This drink doesn't exist or has been removed.")]),
  ])
}

fn populated_view(
  drink: Drink,
  user_rating: Option(Rating),
  other_ratings: List(Rating),
) -> Element(Msg) {
  html.div([attribute.class("drink-detail populated")], [
    drink_header(drink),
    rating_breakdown_section(drink.average_ratings, "Average Ratings"),
    case user_rating {
      Some(rating) -> user_rating_section(rating)
      None -> html.div([], [])
    },
    other_ratings_section(other_ratings),
  ])
}

// Component sections

fn drink_header(drink: Drink) -> Element(Msg) {
  html.div([attribute.class("drink-header")], [
    html.img([
      attribute.src(drink.image_url),
      attribute.alt(drink.name),
      attribute.class("drink-image"),
    ]),
    html.div([attribute.class("drink-info")], [
      html.h1([], [text(drink.name)]),
      html.h2([attribute.class("shop-name")], [text(drink.shop_name)]),
      html.p([attribute.class("description")], [text(drink.description)]),
      html.p([attribute.class("price")], [
        text("$" <> format_price(drink.price)),
      ]),
    ]),
  ])
}

fn rating_breakdown_section(breakdown: RatingBreakdown, title: String) -> Element(Msg) {
  html.div([attribute.class("rating-breakdown-section")], [
    html.h3([], [text(title)]),
    html.div([attribute.class("rating-bars")], [
      rating_bar("Taste", breakdown.taste),
      rating_bar("Texture", breakdown.texture),
      rating_bar("Sweetness", breakdown.sweetness),
      rating_bar("Presentation", breakdown.presentation),
    ]),
    html.div([attribute.class("overall-rating")], [
      text("Overall: " <> format_rating(shared.average_from_breakdown(breakdown)) <> "/5"),
    ]),
  ])
}

fn rating_bar(label: String, value: Float) -> Element(Msg) {
  let percentage = { value /. 5.0 } *. 100.0
  html.div([attribute.class("rating-bar")], [
    html.div([attribute.class("rating-label")], [text(label)]),
    html.div([attribute.class("rating-track")], [
      html.div([
        attribute.class("rating-fill"),
        attribute.style("width", float.to_string(percentage) <> "%"),
      ], []),
    ]),
    html.div([attribute.class("rating-value")], [text(format_rating(value))]),
  ])
}

fn user_rating_section(rating: Rating) -> Element(Msg) {
  html.div([attribute.class("user-rating-section")], [
    html.h3([], [text("Your Rating")]),
    rating_breakdown_section(rating.breakdown, ""),
    case string.is_empty(rating.comment) {
      False -> html.p([attribute.class("user-comment")], [text(rating.comment)])
      True -> html.div([], [])
    },
  ])
}

fn other_ratings_section(ratings: List(Rating)) -> Element(Msg) {
  let rating_count = list.length(ratings)

  html.div([attribute.class("other-ratings-section")], [
    html.h3([], [text("Ratings from other users (" <> int.to_string(rating_count) <> ")")]),
    case ratings {
      [] -> html.p([attribute.class("no-ratings")], [text("No ratings yet. Be the first to rate!")])
      _ -> html.div([attribute.class("rating-cards")], list.map(ratings, rating_card))
    },
  ])
}

fn rating_card(rating: Rating) -> Element(Msg) {
  html.div([attribute.class("rating-card")], [
    html.div([attribute.class("rating-header")], [
      html.span([attribute.class("user-name")], [text(rating.user_name)]),
      html.span([attribute.class("rating-date")], [text(rating.created_at)]),
    ]),
    html.div([attribute.class("mini-breakdown")], [
      mini_rating("Taste", rating.breakdown.taste),
      mini_rating("Texture", rating.breakdown.texture),
      mini_rating("Sweetness", rating.breakdown.sweetness),
      mini_rating("Presentation", rating.breakdown.presentation),
    ]),
    html.div([attribute.class("rating-overall")], [
      text("Overall: " <> format_rating(shared.average_from_breakdown(rating.breakdown)) <> "/5"),
    ]),
    case string.is_empty(rating.comment) {
      False -> html.p([attribute.class("rating-comment")], [text(rating.comment)])
      True -> html.div([], [])
    },
  ])
}

fn mini_rating(label: String, value: Float) -> Element(Msg) {
  html.span([attribute.class("mini-rating")], [
    text(label <> ": " <> format_rating(value)),
  ])
}

// Helpers

fn format_price(price: Float) -> String {
  let dollars = float.truncate(price)
  let cents = float.truncate({ price -. int.to_float(dollars) } *. 100.0)
  let cents_str = int.to_string(cents)
  let padded_cents = case string.length(cents_str) {
    1 -> "0" <> cents_str
    _ -> cents_str
  }
  int.to_string(dollars) <> "." <> padded_cents
}

fn format_rating(value: Float) -> String {
  let rounded = float.round(value *. 10.0)
  let whole = rounded / 10
  let decimal = rounded % 10
  int.to_string(whole) <> "." <> int.to_string(decimal)
}
