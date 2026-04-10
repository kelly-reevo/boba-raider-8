import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import simplifile
import web/server.{type Request, type Response, json_response}

const max_file_size = 5_242_880

const upload_dir = "priv/static/uploads"

pub fn handle_image_upload(request: Request) -> Response {
  let content_type = case dict.get(request.headers, "content-type") {
    Ok(ct) -> ct
    Error(_) -> ""
  }

  case string.starts_with(content_type, "multipart/form-data") {
    False -> json_response(400, error_json("Expected multipart/form-data"))
    True -> {
      let boundary = extract_boundary(content_type)
      case boundary {
        Error(_) -> json_response(400, error_json("Missing boundary in Content-Type"))
        Ok(b) -> {
          case parse_multipart(request.body, b) {
            Error(_) -> json_response(400, error_json("Failed to parse multipart data"))
            Ok(parts) -> {
              case find_file_part(parts) {
                Error(_) -> json_response(400, error_json("No file found in request"))
                Ok(file_data) -> validate_and_store(file_data)
              }
            }
          }
        }
      }
    }
  }
}

fn error_json(msg: String) -> String {
  json.object([#("error", json.string(msg))]) |> json.to_string
}

fn extract_boundary(content_type: String) -> Result(String, Nil) {
  case string.split(content_type, "boundary=") {
    [_, boundary] -> Ok(string.trim(boundary))
    _ -> Error(Nil)
  }
}

type Part {
  Part(headers: Dict(String, String), body: BitArray)
}

fn parse_multipart(body: BitArray, boundary: String) -> Result(List(Part), Nil) {
  let delimiter = bit_array.from_string("--" <> boundary)
  let crlf = bit_array.from_string("\r\n")

  case split_bitarray(body, delimiter) {
    [] -> Error(Nil)
    parts -> {
      let parsed = list.filter_map(parts, fn(p) { parse_part(p, crlf) })
      case list.is_empty(parsed) {
        True -> Error(Nil)
        False -> Ok(parsed)
      }
    }
  }
}

fn parse_part(data: BitArray, crlf: BitArray) -> Result(Part, Nil) {
  let data_size = bit_array.byte_size(data)

  let data = case data_size >= 2 {
    True -> {
      let prefix = slice_bitarray(data, 0, 2)
      case prefix == bit_array.from_string("--") {
        True -> slice_bitarray(data, 2, data_size - 2)
        False -> data
      }
    }
    False -> data
  }

  let data = {
    let current_size = bit_array.byte_size(data)
    case current_size >= 2 {
      True -> {
        let suffix = slice_bitarray(data, current_size - 2, 2)
        case suffix == bit_array.from_string("--") {
          True -> slice_bitarray(data, 0, current_size - 2)
          False -> data
        }
      }
      False -> data
    }
  }

  case find_bitarray_split(data, crlf, 0) {
    Error(_) -> Error(Nil)
    Ok(header_end) -> {
      let header_bytes = slice_bitarray(data, 0, header_end)
      let body_start = header_end + 4

      let body = case bit_array.byte_size(data) > body_start {
        True -> {
          let end_pos = bit_array.byte_size(data)
          let end_pos = case end_pos >= 2 {
            True -> end_pos - 2
            False -> end_pos
          }
          slice_bitarray(data, body_start, end_pos - body_start)
        }
        False -> <<>>
      }

      case bit_array.to_string(header_bytes) {
        Error(_) -> Error(Nil)
        Ok(headers_str) -> {
          let headers = parse_headers(headers_str)
          Ok(Part(headers: headers, body: body))
        }
      }
    }
  }
}

fn parse_headers(header_str: String) -> Dict(String, String) {
  header_str
  |> string.split("\r\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.fold(dict.new(), fn(acc, line) {
    case string.split_once(line, ":") {
      Ok(#(key, value)) -> {
        let key = string.lowercase(string.trim(key))
        let value = string.trim(value)
        dict.insert(acc, key, value)
      }
      Error(_) -> acc
    }
  })
}

fn find_file_part(parts: List(Part)) -> Result(#(String, BitArray), Nil) {
  list.find_map(parts, fn(part) {
    case dict.get(part.headers, "content-disposition") {
      Error(_) -> Error(Nil)
      Ok(disposition) -> {
        case extract_filename(disposition) {
          Error(_) -> Error(Nil)
          Ok(filename) -> Ok(#(filename, part.body))
        }
      }
    }
  })
}

fn extract_filename(disposition: String) -> Result(String, Nil) {
  case string.split(disposition, "filename=\"") {
    [_, rest] -> {
      case string.split(rest, "\"") {
        [filename, ..] -> Ok(filename)
        _ -> Error(Nil)
      }
    }
    _ -> {
      case string.split(disposition, "filename=") {
        [_, rest] -> {
          case string.split(rest, ";") {
            [filename, ..] -> Ok(string.trim(filename))
            _ -> Error(Nil)
          }
        }
        _ -> Error(Nil)
      }
    }
  }
}

fn validate_and_store(file_data: #(String, BitArray)) -> Response {
  let #(filename, data) = file_data
  let size = bit_array.byte_size(data)

  case size > max_file_size {
    True -> json_response(413, error_json("File exceeds maximum size of 5MB"))
    False -> {
      let ext = get_extension(filename) |> string.lowercase
      case is_valid_extension(ext) {
        False -> json_response(415, error_json("Unsupported file type. Only jpg, png, webp allowed"))
        True -> {
          let stored_filename = generate_unique_filename(ext)
          let filepath = upload_dir <> "/" <> stored_filename

          case ensure_upload_dir() {
            Error(_) -> json_response(500, error_json("Failed to create upload directory"))
            Ok(_) -> {
              case simplifile.create_file(filepath) {
                Error(_) -> json_response(500, error_json("Failed to create file"))
                Ok(_) -> {
                  case simplifile.write_bits(filepath, data) {
                    Error(_) -> json_response(500, error_json("Failed to write file"))
                    Ok(_) -> {
                      let url = "/static/uploads/" <> stored_filename
                      json_response(
                        201,
                        json.object([#("image_url", json.string(url))]) |> json.to_string,
                      )
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

fn get_extension(filename: String) -> String {
  case string.split(filename, ".") {
    [] -> ""
    parts -> {
      case list.last(parts) {
        Ok(ext) -> ext
        Error(_) -> ""
      }
    }
  }
}

fn is_valid_extension(ext: String) -> Bool {
  case ext {
    "jpg" | "jpeg" | "png" | "webp" -> True
    _ -> False
  }
}

fn generate_unique_filename(ext: String) -> String {
  let timestamp = int_to_string(erlang_system_time())
  let random = int_to_string(erlang_rand_uniform(1_000_000))
  timestamp <> "_" <> random <> "." <> ext
}

fn ensure_upload_dir() -> Result(Nil, Nil) {
  case simplifile.is_directory(upload_dir) {
    Ok(True) -> Ok(Nil)
    _ -> {
      case simplifile.create_directory_all(upload_dir) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error(Nil)
      }
    }
  }
}

fn split_bitarray(data: BitArray, delimiter: BitArray) -> List(BitArray) {
  do_split(data, delimiter, [])
}

fn do_split(data: BitArray, delimiter: BitArray, acc: List(BitArray)) -> List(BitArray) {
  case find_bitarray_split(data, delimiter, 0) {
    Error(_) -> {
      case bit_array.byte_size(data) == 0 {
        True -> list.reverse(acc)
        False -> list.reverse([data, ..acc])
      }
    }
    Ok(pos) -> {
      let before = slice_bitarray(data, 0, pos)
      let after_pos = pos + bit_array.byte_size(delimiter)
      let after = slice_bitarray(data, after_pos, bit_array.byte_size(data) - after_pos)
      do_split(after, delimiter, [before, ..acc])
    }
  }
}

fn find_bitarray_split(data: BitArray, pattern: BitArray, start: Int) -> Result(Int, Nil) {
  let data_size = bit_array.byte_size(data)
  let pattern_size = bit_array.byte_size(pattern)

  case start + pattern_size > data_size {
    True -> Error(Nil)
    False -> {
      let slice = slice_bitarray(data, start, pattern_size)
      case slice == pattern {
        True -> Ok(start)
        False -> find_bitarray_split(data, pattern, start + 1)
      }
    }
  }
}

fn slice_bitarray(data: BitArray, start: Int, len: Int) -> BitArray {
  case start < 0 || len <= 0 || start >= bit_array.byte_size(data) {
    True -> <<>>
    False -> {
      let available = bit_array.byte_size(data) - start
      let actual_len = case len > available {
        True -> available
        False -> len
      }
      bit_array.slice(data, start, actual_len)
      |> result.unwrap(<<>>)
    }
  }
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int

@external(erlang, "rand", "uniform")
fn erlang_rand_uniform(n: Int) -> Int

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> do_int_to_string(n / 10, char_to_string(n % 10) <> acc)
  }
}

fn char_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> ""
  }
}
