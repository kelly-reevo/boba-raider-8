/// View functions for rendering the UI

import frontend/model.{type DrinkCard, type Model, type PageState, type StoreInfo}
import frontend/msg.{type Msg}
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  case model.page_state {
    model.Loading -> render_loading()
    model.NotFound -> render_404()
    model.Error(msg) -> render_error(msg)
    model.Loaded -> render_store_detail(model)
  }
}

/// Loading state - shown while fetching data
fn render_loading() -> Element(Msg) {
  html.div([attribute.class("loading-container")], [
    html.div([attribute.class("loading-spinner")], []),
    html.p([], [element.text("Loading...")]),
  ])
}

/// 404 error page for invalid store ID
fn render_404() -> Element(Msg) {
  html.div([attribute.class("error-404")], [
    html.h1([], [element.text("404")]),
    html.p([], [element.text("Store not found")]),
  ])
}

/// Generic error display
fn render_error(msg: String) -> Element(Msg) {
  html.div([attribute.class("error-container")], [
    html.h2([], [element.text("Error")]),
    html.p([], [element.text(msg)]),
  ])
}

/// Store detail page with header and drink list
fn render_store_detail(model: Model) -> Element(Msg) {
  html.div([attribute.class("store-detail")], [
    render_store_header(model.store),
    render_add_drink_button(),
    render_drink_section(model.drinks),
  ])
}

/// Store header with name and location
fn render_store_header(store: option.Option(StoreInfo)) -> Element(Msg) {
  case store {
    Some(store_info) -> {
      let location_text = case store_info.location {
        "" -> ""
        loc -> " - " <> loc
      }
      html.header([attribute.class("store-header")], [
        html.h1([], [element.text(store_info.name <> location_text)]),
      ])
    }
    None -> html.div([], [])
  }
}

/// Add Drink button - always shown
fn render_add_drink_button() -> Element(Msg) {
  html.button(
    [
      event.on_click(msg.ClickAddDrink),
      attribute.class("add-drink-button"),
    ],
    [element.text("Add Drink")],
  )
}

/// Drink section - shows list or empty state
fn render_drink_section(drinks: List(DrinkCard)) -> Element(Msg) {
  case drinks {
    [] -> render_empty_state()
    drinks_list -> render_drink_list(drinks_list)
  }
}

/// Empty state - when store has no drinks
fn render_empty_state() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [
    html.p([attribute.class("empty-message")], [
      element.text("No drinks yet. Be the first to add one!"),
    ]),
  ])
}

/// Drink list - renders array of drink cards
fn render_drink_list(drinks: List(DrinkCard)) -> Element(Msg) {
  html.div(
    [attribute.class("drink-list")],
    list.map(drinks, render_drink_card),
  )
}

/// Individual drink card with all required fields
fn render_drink_card(drink: DrinkCard) -> Element(Msg) {
  html.div(
    [attribute.class("drink-card"), attribute.id("drink-" <> drink.id)],
    [
      html.h3([attribute.class("drink-name")], [element.text(drink.name)]),
      html.p([attribute.class("drink-tea-type")], [
        element.text(drink.base_tea_type),
      ]),
      html.p([attribute.class("drink-price")], [
        element.text("$" <> format_price(drink.price)),
      ]),
      html.div([attribute.class("drink-rating")], [
        element.text("Rating: " <> float.to_string(drink.overall_rating)),
      ]),
    ],
  )
}

/// Format price as string with 2 decimal places
fn format_price(price: Float) -> String {
  // Simple formatting - in production would use proper currency formatting
  float.to_string(price)
}
