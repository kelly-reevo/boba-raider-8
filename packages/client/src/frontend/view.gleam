/// View functions for the application

import gleam/float
import gleam/int
import gleam/list
import frontend/model.{
  type Model, type StoreDetailModel, type Store, type Drink,
  type Rating, type AuthState, type StoreData,
  StoreDetailModel, Loading, Loaded, Error as LoadError,
  Authenticated, Anonymous, StoreDetail, Home,
}
import frontend/msg.{type Msg, type StoreDetailMsg, StoreDetailMsg, ClickedAddDrink, ClickedBack}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{error_message}

// --- Main Application View ---

pub fn view(model: Model) -> Element(Msg) {
  case model.current_page {
    Home -> view_home()
    StoreDetail(store_id) -> {
      let store_model = init_store_detail(store_id, model.auth)
      view_store_detail_page(store_model)
    }
  }
}

/// Helper to create a StoreDetailModel (mirrors model.init_store_detail)
fn init_store_detail(store_id: String, auth: AuthState) -> StoreDetailModel {
  StoreDetailModel(
    store_id: store_id,
    data: Loading,
    auth: auth,
  )
}

fn view_home() -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    html.p([], [element.text("Welcome to boba-raider-8")]),
  ])
}

// --- Store Detail Page Component ---

/// Main store detail page view
fn view_store_detail_page(model: StoreDetailModel) -> Element(Msg) {
  html.div([attribute.class("store-detail-page")], [
    view_back_button(),
    case model.data {
      Loading -> view_loading()
      LoadError(e) -> view_error(e)
      Loaded(data) -> view_store_content(data, model.auth)
    },
  ])
}

/// Wrap a StoreDetailMsg in the parent Msg type
fn wrap(msg: StoreDetailMsg) -> Msg {
  StoreDetailMsg(msg)
}

/// Loading state with spinner
fn view_loading() -> Element(Msg) {
  html.div([attribute.class("loading-container")], [
    html.div([attribute.class("spinner")], []),
    html.p([attribute.class("loading-text")], [element.text("Loading store...")]),
  ])
}

/// Error state view
fn view_error(error: shared.AppError) -> Element(Msg) {
  html.div([attribute.class("error-container")], [
    html.div([attribute.class("error-icon")], [element.text("⚠")]),
    html.h2([attribute.class("error-title")], [element.text("Oops!")]),
    html.p([attribute.class("error-message")], [
      element.text(error_message(error)),
    ]),
    html.button(
      [attribute.class("retry-button"), event.on_click(wrap(ClickedBack))],
      [element.text("Go Back")],
    ),
  ])
}

/// Back button for navigation
fn view_back_button() -> Element(Msg) {
  html.button(
    [
      attribute.class("back-button"),
      event.on_click(wrap(ClickedBack)),
    ],
    [element.text("← Back")],
  )
}

/// Full store content when data is loaded
fn view_store_content(data: StoreData, auth: AuthState) -> Element(Msg) {
  html.div([attribute.class("store-content")], [
    // Store header section
    view_store_header(data.store),

    // Map location section
    view_map_location(data.store),

    // Add Drink button (only for authenticated users)
    view_add_drink_button(auth),

    // Drinks list section
    view_drinks_section(data.drinks),

    // Ratings section
    view_ratings_section(data.ratings),
  ])
}

/// Store header with name and basic info
fn view_store_header(store: Store) -> Element(Msg) {
  html.div([attribute.class("store-header")], [
    html.h1([attribute.class("store-name")], [element.text(store.name)]),
    html.div([attribute.class("store-meta")], [
      html.span([attribute.class("store-category")], [element.text(store.description)]),
    ]),
    html.div([attribute.class("store-contact")], [
      html.p([], [
        html.span([attribute.class("label")], [element.text("Address: ")]),
        element.text(store.address <> ", " <> store.city <> ", " <> store.state <> " " <> store.zip),
      ]),
      html.p([], [
        html.span([attribute.class("label")], [element.text("Phone: ")]),
        element.text(store.phone),
      ]),
      html.a(
        [
          attribute.href(store.website),
          attribute.target("_blank"),
          attribute.class("store-website"),
        ],
        [element.text("Visit Website")],
      ),
    ]),
  ])
}

/// Map location section
fn view_map_location(store: Store) -> Element(Msg) {
  html.div([attribute.class("map-section")], [
    html.h2([], [element.text("Location")]),
    html.div(
      [
        attribute.class("map-container"),
        // Data attributes for map initialization
        attribute.attribute("data-lat", float.to_string(store.latitude)),
        attribute.attribute("data-lng", float.to_string(store.longitude)),
        attribute.attribute("data-name", store.name),
      ],
      [
        // Static map placeholder - in production this would integrate with a map library
        html.div([attribute.class("map-placeholder")], [
          element.text("📍 " <> store.name),
          html.br([]),
          element.text(
            "Coordinates: "
            <> float.to_string(store.latitude)
            <> ", "
            <> float.to_string(store.longitude),
          ),
        ]),
      ],
    ),
  ])
}

/// Add drink button (only shown for authenticated users)
fn view_add_drink_button(auth: AuthState) -> Element(Msg) {
  case auth {
    Authenticated(_, _) -> {
      html.div([attribute.class("add-drink-section")], [
        html.button(
          [
            attribute.class("add-drink-button"),
            event.on_click(wrap(ClickedAddDrink)),
          ],
          [element.text("+ Add Drink")],
        ),
      ])
    }
    Anonymous -> {
      // Empty element for anonymous users
      element.none()
    }
  }
}

/// Drinks list section
fn view_drinks_section(drinks: List(Drink)) -> Element(Msg) {
  html.div([attribute.class("drinks-section")], [
    html.h2([], [element.text("Drinks")]),
    case drinks {
      [] -> html.p([attribute.class("empty-state")], [element.text("No drinks listed yet.")])
      _ -> html.div([attribute.class("drinks-list")], list.map(drinks, view_drink_card))
    },
  ])
}

/// Single drink card
fn view_drink_card(drink: Drink) -> Element(Msg) {
  html.div([attribute.class("drink-card")], [
    html.div([attribute.class("drink-image")], [
      html.img([
        attribute.src(drink.image_url),
        attribute.alt(drink.name),
      ]),
    ]),
    html.div([attribute.class("drink-info")], [
      html.h3([attribute.class("drink-name")], [element.text(drink.name)]),
      html.p([attribute.class("drink-category")], [element.text(drink.category)]),
      html.p([attribute.class("drink-description")], [element.text(drink.description)]),
      html.div([attribute.class("drink-price")], [
        element.text(drink.currency <> format_price(drink.price)),
      ]),
    ]),
  ])
}

fn format_price(price: Float) -> String {
  // Format to 2 decimal places
  let whole = float.truncate(price)
  let decimal = float.truncate({price -. int.to_float(whole)} *. 100.0)
  int.to_string(whole) <> "." <> case decimal {
    d if d < 10 -> "0" <> int.to_string(d)
    d -> int.to_string(d)
  }
}

/// Ratings section
fn view_ratings_section(ratings: List(Rating)) -> Element(Msg) {
  html.div([attribute.class("ratings-section")], [
    html.h2([], [element.text("Reviews")]),
    case ratings {
      [] -> html.p([attribute.class("empty-state")], [element.text("No reviews yet. Be the first to review!")])
      _ -> html.div([attribute.class("ratings-list")], list.map(ratings, view_rating_card))
    },
  ])
}

/// Single rating card
fn view_rating_card(rating: Rating) -> Element(Msg) {
  html.div([attribute.class("rating-card")], [
    html.div([attribute.class("rating-header")], [
      html.span([attribute.class("rating-username")], [element.text(rating.username)]),
      html.span([attribute.class("rating-date")], [element.text(rating.created_at)]),
    ]),
    html.div([attribute.class("rating-stars")], [
      element.text(render_stars(rating.rating)),
    ]),
    html.p([attribute.class("rating-review")], [element.text(rating.review)]),
  ])
}

fn render_stars(rating: Int) -> String {
  case rating {
    5 -> "★★★★★"
    4 -> "★★★★☆"
    3 -> "★★★☆☆"
    2 -> "★★☆☆☆"
    1 -> "★☆☆☆☆"
    0 -> "☆☆☆☆☆"
    _ -> "★★★★★"
  }
}
