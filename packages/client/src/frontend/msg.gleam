/// Application messages with operation lifecycle statuses and error handling

import shared.{type Filter, type Todo}

/// Error container types for targeted dismissal
pub type ErrorContainer {
  ListErrorContainer
  FormErrorContainer
  GlobalErrorContainer
}

/// Operation status for async operations
pub type Status {
  Start
  Success
  Error(String)
}

/// Main message type covering all operations
pub type Msg {
  // Todo list fetching
  FetchTodos(status: Status, payload: FetchTodosPayload)

  // Add todo
  AddTodo(status: Status, payload: AddTodoPayload)

  // Toggle todo completion
  ToggleTodo(status: Status, payload: ToggleTodoPayload)

  // Delete todo
  DeleteTodo(status: Status, payload: DeleteTodoPayload)

  // Filter change
  SetFilter(filter: Filter)

  // Form input updates
  UpdateTitle(title: String)
  UpdateDescription(description: String)

  // Error management
  ClearTransientError
  DismissError(container: ErrorContainer)
}

/// Payload types for each operation
pub type FetchTodosPayload {
  NoFetchPayload
  TodosList(items: List(Todo))
}

pub type AddTodoPayload {
  NoAddPayload
  NewTodo(item: Todo)
  AddFormData(title: String, description: String)
}

pub type ToggleTodoPayload {
  NoTogglePayload
  ToggleData(id: String, completed: Bool)
  ToggledTodo(item: Todo)
}

pub type DeleteTodoPayload {
  NoDeletePayload
  DeleteData(id: String)
  DeleteResult(deleted_id: String)
}
