import gleam/option.{type Option, None}
import shared.{type Store}

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
  )
}
