import shared.{type Store}

pub type LoadState {
  Loading
  Loaded
  Failed(String)
}

pub type Model {
  Model(stores: List(Store), search_query: String, load_state: LoadState)
}

pub fn default() -> Model {
  Model(stores: [], search_query: "", load_state: Loading)
}
