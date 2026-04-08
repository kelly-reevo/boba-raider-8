import gleam/option.{type Option, None}
import shared.{type FrontendDrink, type Store}

pub type LoadState {
  Loading
  Loaded
  Failed(String)
}

pub type Page {
  LoginPage
  RegisterPage
  ProfilePage
  StoreListPage
  StoreDetailPage(store_id: String)
}

pub type AuthUser {
  AuthUser(id: String, username: String, email: String)
}

pub type Model {
  Model(
    page: Page,
    token: Option(String),
    user: Option(AuthUser),
    email: String,
    password: String,
    username: String,
    loading: Bool,
    error: String,
    stores: List(Store),
    search_query: String,
    store_load_state: LoadState,
    store: Option(Store),
    drinks: List(FrontendDrink),
  )
}

pub fn default() -> Model {
  Model(
    page: LoginPage,
    token: None,
    user: None,
    email: "",
    password: "",
    username: "",
    loading: False,
    error: "",
    stores: [],
    search_query: "",
    store_load_state: Loading,
    store: None,
    drinks: [],
  )
}
