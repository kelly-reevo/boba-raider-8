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
