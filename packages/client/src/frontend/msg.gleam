/// Application messages

import shared.{type Todo}

/// Message type for all application events
pub type Msg {
  // Counter messages (legacy)
  Increment
  Decrement
  Reset

  // Todo list messages
  LoadTodos
  TodosLoaded(Result(List(Todo), String))
  ToggleTodo(String)
  DeleteTodo(String)
}
