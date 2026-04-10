/// Route definitions and authentication guards

import gleam/string

/// Represents all application routes
pub type Route {
  Home
  StoreList
  StoreDetail(id: String)
  StoreCreate
  StoreEdit(id: String)
  DrinkDetail(id: String)
  DrinkEdit(id: String)
  Profile
  Login
  Register
  NotFound(path: String)
}

/// Check if a route requires authentication
pub fn is_protected(route: Route) -> Bool {
  case route {
    Profile -> True
    StoreCreate -> True
    StoreEdit(_) -> True
    DrinkEdit(_) -> True
    _ -> False
  }
}

/// Get the redirect path for authentication
pub fn login_redirect_path() -> String {
  "/login"
}

/// Convert a route to its path string
pub fn to_path(route: Route) -> String {
  case route {
    Home -> "/"
    StoreList -> "/stores"
    StoreDetail(id) -> "/stores/" <> id
    StoreCreate -> "/stores/create"
    StoreEdit(id) -> "/stores/" <> id <> "/edit"
    DrinkDetail(id) -> "/drinks/" <> id
    DrinkEdit(id) -> "/drinks/" <> id <> "/edit"
    Profile -> "/profile"
    Login -> "/login"
    Register -> "/register"
    NotFound(path) -> path
  }
}

/// Parse a path string into a Route
pub fn from_path(path: String) -> Route {
  case path {
    "/" -> Home
    "/stores" -> StoreList
    "/stores/create" -> StoreCreate
    "/login" -> Login
    "/register" -> Register
    "/profile" -> Profile
    _ -> parse_dynamic_path(path)
  }
}

/// Parse paths with dynamic segments
fn parse_dynamic_path(path: String) -> Route {
  let parts = string.split(path, "/")

  case parts {
    ["", "stores", id] -> StoreDetail(id)
    ["", "stores", id, "edit"] -> StoreEdit(id)
    ["", "drinks", id] -> DrinkDetail(id)
    ["", "drinks", id, "edit"] -> DrinkEdit(id)
    _ -> NotFound(path)
  }
}
