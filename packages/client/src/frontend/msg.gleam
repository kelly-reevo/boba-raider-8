/// Application messages

import shared.{type Todo}

/// Msg type for all UI interactions and API responses
pub type Msg {
  // Todo list loading
  LoadTodos
  LoadTodosOk(List(Todo))
  LoadTodosError(String)

  // Delete todo with user confirmation
  RequestDelete(String)
  ConfirmDelete(String)
  CancelDelete
  DeleteTodoOk(String)
  DeleteTodoError(String)
}
