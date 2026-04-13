/// Application messages

import shared.{type Todo}

pub type Msg {
  // Todo list messages
  ToggleTodo(id: String, completed: Bool)
  ToggleTodoSuccess(item: Todo)
  ToggleTodoError(id: String, previous_state: Bool, error: String)

  // Data loading
  LoadTodos
  LoadTodosSuccess(items: List(Todo))
  LoadTodosError(error: String)
}
