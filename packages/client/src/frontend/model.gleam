/// Application state

import gleam/option.{type Option, None}
import shared

pub type Page {
  LoginPage
  RegisterPage
  ProfilePage
}

pub type Model {
  Model(
    page: Page,
    token: Option(String),
    user: Option(shared.User),
    email: String,
    password: String,
    username: String,
    loading: Bool,
    error: String,
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
  )
}
