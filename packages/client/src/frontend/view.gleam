import gleam/float
import gleam/int
import gleam/list
import gleam/string
import frontend/model.{type Model, Failed, Loaded, Loading}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Store}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    search_bar(model.search_query),
    store_content(model),
  ])
}

fn search_bar(query: String) -> Element(Msg) {
  html.div([attribute.class("search-bar")], [
    html.input([
      attribute.type_("text"),
      attribute.placeholder("Search stores..."),
      attribute.value(query),
      event.on_input(msg.UserUpdatedSearch),
    ]),
  ])
}

fn store_content(model: Model) -> Element(Msg) {
  case model.load_state {
    Loading -> loading_view()
    Failed(err) -> error_view(err)
    Loaded -> {
      let filtered = filter_stores(model.stores, model.search_query)
      case filtered {
        [] -> empty_view(model.search_query)
        stores -> store_grid(stores)
      }
    }
  }
}

fn loading_view() -> Element(Msg) {
  html.div([attribute.class("loading")], [
    html.p([], [element.text("Loading stores...")]),
  ])
}

fn error_view(message: String) -> Element(Msg) {
  html.div([attribute.class("error")], [
    html.p([], [element.text("Failed to load stores: " <> message)]),
  ])
}

fn empty_view(query: String) -> Element(Msg) {
  let message = case query {
    "" -> "No stores found."
    _ -> "No stores match \"" <> query <> "\"."
  }
  html.div([attribute.class("empty")], [
    html.p([], [element.text(message)]),
  ])
}

fn store_grid(stores: List(Store)) -> Element(Msg) {
  html.div(
    [attribute.class("store-grid")],
    list.map(stores, store_card),
  )
}

fn store_card(store: Store) -> Element(Msg) {
  html.div([attribute.class("store-card")], [
    html.h3([attribute.class("store-name")], [element.text(store.name)]),
    html.p([attribute.class("store-address")], [element.text(store.address)]),
    html.p([attribute.class("store-description")], [
      element.text(store.description),
    ]),
    rating_badge(store.average_rating, store.rating_count),
  ])
}

fn rating_badge(average: Float, count: Int) -> Element(Msg) {
  html.div([attribute.class("rating")], [
    html.span([attribute.class("rating-stars")], [
      element.text(format_rating(average)),
    ]),
    html.span([attribute.class("rating-count")], [
      element.text("(" <> int.to_string(count) <> " reviews)"),
    ]),
  ])
}

fn format_rating(rating: Float) -> String {
  // Display one decimal place
  let whole = float.truncate(rating)
  let frac = float.truncate({ rating -. int.to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(frac)
}

fn filter_stores(stores: List(Store), query: String) -> List(Store) {
  case string.trim(query) {
    "" -> stores
    q -> {
      let lower_q = string.lowercase(q)
      list.filter(stores, fn(store) {
        string.contains(string.lowercase(store.name), lower_q)
        || string.contains(string.lowercase(store.address), lower_q)
        || string.contains(string.lowercase(store.description), lower_q)
      })
    }
  }
}
