/// Application state with routing and authentication support

import gleam/option.{type Option, None, Some}
import shared.{type User}

pub type Model {
  Model(count: Int, error: String, user: Option(User))
}

pub fn default() -> Model {
  Model(count: 0, error: "", user: None)
}

/// Check if user is authenticated
pub fn is_authenticated(model: Model) -> Bool {
  case model.user {
    Some(_) -> True
    None -> False
  }
}
