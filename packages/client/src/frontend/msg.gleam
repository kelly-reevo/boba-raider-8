/// Application messages for todo list operations

import shared.{type Todo}

/// Messages for the todo list application
pub type Msg {
  // Initial data loading
  LoadTodos
  TodosLoaded(Result(List(Todo), String))
  LoadTodosOk(List(Todo))
  LoadTodosError(String)

  // Todo creation
  TodoCreated(Todo)

  // Todo updates
  TodoUpdated(Todo)

  // Todo deletion with confirmation flow
  RequestDelete(String)
  ConfirmDelete(String)
  CancelDelete
  DeleteTodoOk(String)
  DeleteTodoError(String)
  TodoDeleted(String)

  // Toggle completion
  ToggleTodoComplete(id: String, completed: Bool)

  // User delete action
  DeleteTodo(id: String)
}
