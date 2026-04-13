/// Application messages

import shared.{type Todo}

pub type Msg {
  // Delete item messages
  DeleteTodo(String)
  DeleteTodoSuccess(String)
  DeleteTodoError(String)

  // Load todos messages
  LoadTodos
  TodosLoaded(List(Todo))
  TodosLoadError(String)
}
