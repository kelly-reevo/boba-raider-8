import shared.{type Todo}

/// Application messages
pub type Msg {
  FetchTodos
  GotTodos(Result(List(Todo), String))
}
