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
        headers: gleam.dict.from_list([#("Content-Type", content_type)]),
        body: content,
      )
    Error(_) -> server.text_response(404, "Not found")
  }
}

fn get_content_type(path: String) -> String {
  case True {
    _ if string.ends_with(path, ".html") -> "text/html; charset=utf-8"
    _ if string.ends_with(path, ".css") -> "text/css"
    _ if string.ends_with(path, ".js") -> "application/javascript"
    _ if string.ends_with(path, ".mjs") -> "application/javascript"
    _ if string.ends_with(path, ".json") -> "application/json"
    _ if string.ends_with(path, ".png") -> "image/png"
    _ if string.ends_with(path, ".svg") -> "image/svg+xml"
    _ -> "application/octet-stream"
  }
}
