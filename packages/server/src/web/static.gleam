import gleam/dict
import gleam/string
import simplifile
import web/server.{type Response}

pub fn serve_index() -> Response {
  serve_file("priv/static/index.html", "text/html; charset=utf-8")
}

pub fn serve(path: String) -> Response {
  let file_path = "priv" <> path
  let content_type = get_content_type(path)
  serve_file(file_path, content_type)
}

fn serve_file(path: String, content_type: String) -> Response {
  case simplifile.read(path) {
    Ok(content) ->
      server.Response(
        status: 200,
        headers: dict.from_list([#("Content-Type", content_type)]),
        body: content,
      )
    Error(_) -> server.text_response(404, "Not found")
  }
}

fn get_content_type(path: String) -> String {
  case string.ends_with(path, ".html") {
    True -> "text/html; charset=utf-8"
    False ->
      case string.ends_with(path, ".css") {
        True -> "text/css"
        False ->
          case string.ends_with(path, ".js") {
            True -> "application/javascript"
            False ->
              case string.ends_with(path, ".mjs") {
                True -> "application/javascript"
                False ->
                  case string.ends_with(path, ".json") {
                    True -> "application/json"
                    False ->
                      case string.ends_with(path, ".png") {
                        True -> "image/png"
                        False ->
                          case string.ends_with(path, ".svg") {
                            True -> "image/svg+xml"
                            False -> "application/octet-stream"
                          }
                      }
                  }
              }
          }
      }
  }
}
