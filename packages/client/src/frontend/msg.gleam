import shared.{type Todo}

/// Application messages
pub type Msg {
  // Data loading
  FetchTodos
  FetchTodosSuccess(List(Todo))
  FetchTodosError(String)
  LoadTodos
  TodosLoaded(List(Todo))
  TodosLoadFailed(String)

  // Toggle todo
  ToggleTodo(String, Bool)
  ToggleTodoSuccess(Todo)
  ToggleTodoError(String, Bool, String)
  TodoUpdated(Todo)
  TodoUpdateFailed(String)

  // Delete todo
  DeleteTodo(String)
  TodoDeleted(String)
  TodoDeleteFailed(String)
}
