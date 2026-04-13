import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

// Minimal wisp compatibility layer for tests

/// HTTP Method type
pub type Method {
  Get
  Post
  Put
  Delete
  Patch
  Head
  Options
  Connect
  Trace
}

/// Request body type
pub type Body {
  TextBody(String)
  EmptyBody
  FileBody(String, String, Int)
}

/// Request type (simplified for testing)
pub type Request {
  Request(
    method: Method,
    path: String,
    query: Dict(String, String),
    headers: Dict(String, String),
    body: Body,
  )
}

/// Response type (simplified for testing)
pub type Response {
  Response(
    status: Int,
    headers: Dict(String, String),
    body: Body,
  )
}

/// Create a new response with given status
pub fn response(status: Int) -> Response {
  Response(status: status, headers: dict.new(), body: EmptyBody)
}

/// Set response body
pub fn set_body(resp: Response, body: Body) -> Response {
  Response(..resp, body: body)
}

/// Not found response
pub fn not_found() -> Response {
  Response(status: 404, headers: dict.new(), body: EmptyBody)
}

/// Read body with max size (simplified - just returns the text body)
pub fn read_body(req: Request, _max_size: Int, next: fn(Body) -> Response) -> Response {
  next(req.body)
}

/// Get response body as string for testing assertions
pub fn get_response_body(resp: Response) -> String {
  case resp.body {
    TextBody(text) -> text
    EmptyBody -> ""
    FileBody(_, _, _) -> ""
  }
}

/// Get request body as string
pub fn get_request_body(req: Request) -> String {
  case req.body {
    TextBody(text) -> text
    EmptyBody -> ""
    FileBody(_, _, _) -> ""
  }
}

// JSON compatibility functions for tests

/// Decode JSON string to Dynamic
pub fn decode(json_string: String) -> Result(dynamic.Dynamic, json.DecodeError) {
  json.parse(json_string, decode.dynamic)
}

/// Get a field from a JSON object.
/// Returns Some(json_value) if found, None otherwise.
/// The returned Json value can be compared directly.
pub fn field(json_obj: dynamic.Dynamic, field_name: String) -> Option(json.Json) {
  // Decode as a dict of Json values
  let dict_decoder = decode.dict(decode.string, decode.dynamic)
  case decode.run(json_obj, dict_decoder) {
    Ok(d) -> {
      case dict.get(d, field_name) {
        Ok(dyn_value) -> {
          // Convert the dynamic value back to a Json value
          Some(dynamic_to_json(dyn_value))
        }
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}

/// Convert a dynamic value to Json
fn dynamic_to_json(value: dynamic.Dynamic) -> json.Json {
  // Try different types
  case decode.run(value, decode.string) {
    Ok(s) -> json.string(s)
    Error(_) -> {
      case decode.run(value, decode.int) {
        Ok(i) -> json.int(i)
        Error(_) -> {
          case decode.run(value, decode.float) {
            Ok(f) -> json.float(f)
            Error(_) -> {
              case decode.run(value, decode.bool) {
                Ok(b) -> json.bool(b)
                Error(_) -> {
                  // Try as null (None)
                  case decode.run(value, decode.optional(decode.string)) {
                    Ok(None) -> json.null()
                    _ -> {
                      // Try as array
                      case decode.run(value, decode.list(decode.dynamic)) {
                        Ok(arr) -> json.array(arr, dynamic_to_json)
                        Error(_) -> {
                          // Try as object
                          case decode.run(value, decode.dict(decode.string, decode.dynamic)) {
                            Ok(obj_dict) -> {
                              let pairs = dict.to_list(obj_dict)
                              json.object(list.map(pairs, fn(pair) {
                                #(pair.0, dynamic_to_json(pair.1))
                              }))
                            }
                            Error(_) -> json.null()
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
