import shared.{type Todo}

/// Application messages

pub type Msg {
  // Toggle completion
  ToggleTodo(id: String, completed: Bool)
  TodoToggledOk(item: Todo)
  TodoToggledError(id: String, original_completed: Bool)

  // Load todos
  TodosLoaded(items: List(Todo))

  // Error handling
  SetError(message: String)
}
