import frontend/model.{type Model, HomePage, StoreDetailPage}
import frontend/msg.{type Msg}
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import shared

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    case model.page {
      HomePage -> view_home()
      StoreDetailPage(_) -> view_store_detail(model)
    },
  ])
}

fn view_home() -> Element(Msg) {
  html.div([attribute.class("home")], [
    html.p([], [element.text("Select a store to view details.")]),
  ])
}

fn view_store_detail(model: Model) -> Element(Msg) {
  html.div([attribute.class("store-detail")], [
    case model.loading, model.error {
      True, _ -> view_loading()
      _, err if err != "" -> view_error(err)
      _, _ -> view_store_content(model)
    },
  ])
}

fn view_loading() -> Element(Msg) {
  html.div([attribute.class("loading")], [
    html.p([], [element.text("Loading store details...")]),
  ])
}

fn view_error(message: String) -> Element(Msg) {
  html.div([attribute.class("error")], [
    html.p([attribute.class("error-message")], [element.text(message)]),
  ])
}

fn view_store_content(model: Model) -> Element(Msg) {
  case model.store {
    option.None -> view_not_found()
    option.Some(store) ->
      html.div([], [
        view_store_info(store),
        view_drink_list(model.drinks),
      ])
  }
}

fn view_not_found() -> Element(Msg) {
  html.div([attribute.class("not-found")], [
    html.p([], [element.text("Store not found.")]),
  ])
}

fn view_store_info(store: shared.Store) -> Element(Msg) {
  html.section([attribute.class("store-info")], [
    html.h2([], [element.text(store.name)]),
    html.p([attribute.class("store-address")], [element.text(store.address)]),
    html.p([attribute.class("store-description")], [
      element.text(store.description),
    ]),
    view_rating(store.average_rating, store.total_ratings),
  ])
}

fn view_rating(average: Float, total: Int) -> Element(Msg) {
  html.div([attribute.class("rating")], [
    html.span([attribute.class("rating-value")], [
      element.text(float.to_string(average)),
    ]),
    html.span([attribute.class("rating-count")], [
      element.text(" (" <> int.to_string(total) <> " ratings)"),
    ]),
  ])
}

fn view_drink_list(drinks: List(shared.Drink)) -> Element(Msg) {
  html.section([attribute.class("drink-menu")], [
    html.h3([], [element.text("Menu")]),
    case list.is_empty(drinks) {
      True -> view_empty_drinks()
      False ->
        html.ul(
          [attribute.class("drink-list")],
          list.map(drinks, view_drink_item),
        )
    },
  ])
}

fn view_empty_drinks() -> Element(Msg) {
  html.p([attribute.class("empty-state")], [
    element.text("No drinks available at this store."),
  ])
}

fn view_drink_item(drink: shared.Drink) -> Element(Msg) {
  html.li([attribute.class("drink-item")], [
    html.div([attribute.class("drink-header")], [
      html.span([attribute.class("drink-name")], [element.text(drink.name)]),
      html.span([attribute.class("drink-price")], [
        element.text(format_price(drink.price_cents)),
      ]),
    ]),
    html.p([attribute.class("drink-description")], [
      element.text(drink.description),
    ]),
    view_rating(drink.average_rating, drink.total_ratings),
  ])
}

fn format_price(cents: Int) -> String {
  let dollars = cents / 100
  let remainder = cents % 100
  "$"
  <> int.to_string(dollars)
  <> "."
  <> case remainder < 10 {
    True -> "0" <> int.to_string(remainder)
    False -> int.to_string(remainder)
  }
}
