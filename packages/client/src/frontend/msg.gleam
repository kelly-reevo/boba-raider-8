import shared.{type Todo}

/// Application messages
pub type Msg {
  FetchTodos
  FetchTodosSuccess(List(Todo))
  FetchTodosError(String)
  ToggleTodo(String, Bool)
  DeleteTodo(String)
}
