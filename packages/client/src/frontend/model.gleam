/// Application state

import gleam/option.{type Option, None}
import shared

pub type Page {
  HomePage
  StoreDetailPage(store_id: String)
}

pub type Model {
  Model(
    page: Page,
    store: Option(shared.Store),
    drinks: List(shared.Drink),
    loading: Bool,
    error: String,
  )
}

pub fn default() -> Model {
  Model(page: HomePage, store: None, drinks: [], loading: False, error: "")
}
