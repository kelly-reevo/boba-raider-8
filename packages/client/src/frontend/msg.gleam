/// Application messages

import shared.{type Todo}

pub type Msg {
  // Toggle todo messages
  ToggleTodo(id: String, completed: Bool)
  ToggleTodoSuccess(item: Todo)
  ToggleTodoError(id: String, previous_state: Bool, error: String)

  // Delete item messages
  DeleteTodo(String)
  DeleteTodoSuccess(String)
  DeleteTodoError(String)

  // Data loading messages
  LoadTodos
  LoadTodosSuccess(items: List(Todo))
  LoadTodosError(error: String)
  TodosLoaded(List(Todo))
  TodosLoadError(String)
}
