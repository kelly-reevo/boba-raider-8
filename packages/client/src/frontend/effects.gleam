/// API effects for the frontend

import frontend/msg.{type Msg, StoreList}
import gleam/fetch
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/string
import lustre/effect.{type Effect}
import shared.{type StoreFilters}

/// Base API URL
const api_base = "/api"

/// Build query string from filters
fn build_query_string(filters: StoreFilters) -> String {
  let query_param = case string.is_empty(filters.query) {
    True -> ""
    False -> "q=" <> percent_encode(filters.query)
  }

  let location_param = case string.is_empty(filters.location) {
    True -> ""
    False -> "location=" <> percent_encode(filters.location)
  }

  let sort_param = "sort=" <> shared.sort_to_string(filters.sort)
  let page_param = "page=" <> int.to_string(filters.page)

  [
    query_param,
    location_param,
    sort_param,
    page_param,
  ]
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> string.join("&")
  |> fn(s) {
    case string.is_empty(s) {
      True -> ""
      False -> "?" <> s
    }
  }
}

/// Simple percent encoding for query parameters
fn percent_encode(s: String) -> String {
  // Replace common special characters
  s
  |> string.replace(" ", "%20")
  |> string.replace("&", "%26")
  |> string.replace("=", "%3D")
  |> string.replace("?", "%3F")
  |> string.replace("#", "%23")
}

/// Fetch stores with filters
pub fn fetch_stores(filters: StoreFilters) -> Effect(Msg) {
  let query_string = build_query_string(filters)
  let url = api_base <> "/stores" <> query_string

  effect.from(fn(dispatch) {
    // Create the request
    let req_result = request.to(url)

    case req_result {
      Error(_) -> {
        dispatch(StoreList(msg.StoresLoaded(Error("Invalid URL"))))
        Nil
      }
      Ok(req) -> {
        let req = request.set_method(req, http.Get)

        // Fire-and-forget pattern: chain promises without returning them
        do_fetch(req, dispatch)
        Nil
      }
    }
  })
}

/// Execute fetch and process response
fn do_fetch(req: Request(String), dispatch: fn(Msg) -> Nil) {
  fetch.send(req)
  |> promise.map(fn(response_result) {
    process_response(response_result, dispatch)
  })
}

/// Process the fetch response
fn process_response(
  response_result: Result(Response(fetch.FetchBody), fetch.FetchError),
  dispatch: fn(Msg) -> Nil,
) -> Nil {
  case response_result {
    Error(_) -> {
      dispatch(StoreList(msg.StoresLoaded(Error("Network error"))))
      Nil
    }
    Ok(response) -> {
      let status = response.status
      case status {
        200 -> {
          // Read the body as text
          do_read_body(response, dispatch)
          Nil
        }
        _ -> {
          dispatch(StoreList(msg.StoresLoaded(Error("Server error: " <> int.to_string(status)))))
          Nil
        }
      }
    }
  }
}

/// Read response body
fn do_read_body(response: Response(fetch.FetchBody), dispatch: fn(Msg) -> Nil) {
  fetch.read_text_body(response)
  |> promise.map(fn(body_result) {
    process_body(body_result, dispatch)
  })
}

/// Process the response body
fn process_body(
  body_result: Result(Response(String), fetch.FetchError),
  dispatch: fn(Msg) -> Nil,
) {
  case body_result {
    Error(_) -> {
      dispatch(StoreList(msg.StoresLoaded(Error("Failed to read response"))))
    }
    Ok(body_response) -> {
      let body = body_response.body
      // Decode the JSON
      case shared.decode_store_list(body) {
        Error(_) -> {
          dispatch(StoreList(msg.StoresLoaded(Error("Failed to parse stores"))))
        }
        Ok(stores) -> {
          dispatch(StoreList(msg.StoresLoaded(Ok(stores))))
        }
      }
    }
  }
}

/// Perform the actual logout via FFI
@external(javascript, "../ffi.mjs", "logout")
fn do_logout() -> Nil {
  Nil
}

/// Save auth token to localStorage on login
pub fn save_token_to_storage(user: User, token: AuthToken) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_save_to_storage(user, token)
    dispatch(TokenCleared)
  })
}

/// Clear auth token from localStorage on logout
pub fn clear_token() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_clear_storage()
    dispatch(TokenCleared)
  })
}

// ---------------------------------------------------------------------------
// localStorage FFI
// ---------------------------------------------------------------------------

/// Load auth data from localStorage - returns tuple of user and token
@external(javascript, "./client_ffi.mjs", "loadAuthFromStorage")
fn do_load_from_storage() -> Result(#(User, AuthToken), String)

/// Save auth data to localStorage
@external(javascript, "./client_ffi.mjs", "saveAuthToStorage")
fn do_save_to_storage(user: User, token: AuthToken) -> Bool

/// Clear auth data from localStorage
@external(javascript, "./client_ffi.mjs", "clearAuthFromStorage")
fn do_clear_storage() -> Nil

// ---------------------------------------------------------------------------
// API Effects
// ---------------------------------------------------------------------------

/// Submit login credentials to API
pub fn submit_login(email: String, password: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call - replace with actual HTTP request
    case do_login_api_call(email, password) {
      Ok(response) -> dispatch(LoginSuccess(response))
      Error(err) -> dispatch(LoginFailure(err))
    }
  })
}

/// Submit registration data to API
pub fn submit_register(
  username: String,
  email: String,
  password: String,
) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call - replace with actual HTTP request
    case do_register_api_call(username, email, password) {
      Ok(response) -> dispatch(RegisterSuccess(response))
      Error(err) -> dispatch(RegisterFailure(err))
    }
  })
}

// ---------------------------------------------------------------------------
// API FFI
// ---------------------------------------------------------------------------

/// Perform login API call
@external(javascript, "./client_ffi.mjs", "loginApiCall")
fn do_login_api_call(email: String, password: String) -> Result(AuthResponse, shared.AppError)

/// Perform registration API call
@external(javascript, "./client_ffi.mjs", "registerApiCall")
fn do_register_api_call(username: String, email: String, password: String) -> Result(AuthResponse, shared.AppError)
