import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

pub type TodoValue {
  TodoString(String)
  TodoBool(Bool)
  TodoNil
}

pub type TodoItem = Dict(String, TodoValue)

pub fn new_item() -> TodoItem {
  dict.new()
}

pub fn with_string(item: TodoItem, key: String, value: String) -> TodoItem {
  dict.insert(item, key, TodoString(value))
}

pub fn with_bool(item: TodoItem, key: String, value: Bool) -> TodoItem {
  dict.insert(item, key, TodoBool(value))
}

pub fn get_string(item: TodoItem, key: String) -> Option(String) {
  case dict.get(item, key) {
    Ok(TodoString(s)) -> Some(s)
    _ -> None
  }
}

pub fn get_bool(item: TodoItem, key: String) -> Option(Bool) {
  case dict.get(item, key) {
    Ok(TodoBool(b)) -> Some(b)
    _ -> None
  }
}

pub fn to_option(result: Result(TodoItem, a)) -> Option(TodoItem) {
  case result {
    Ok(item) -> Some(item)
    Error(_) -> None
  }
}
