/// Application messages

pub type Msg {
  // Counter messages (legacy)
  Increment
  Decrement
  Reset

  // Loading state messages
  SetListLoading(Bool)
  SetFormLoading(Bool)
  SetTodoLoading(String, Bool)
  ClearLoadingStates

  // API response messages
  LoadTodosRequest
  LoadTodosSuccess(List(Todo))
  LoadTodosError(String)

  SubmitTodoRequest
  SubmitTodoSuccess(Todo)
  SubmitTodoError(String)

  ToggleTodoRequest(String, Bool)
  ToggleTodoSuccess(Todo)
  ToggleTodoError(String)

  DeleteTodoRequest(String)
  DeleteTodoSuccess(String)
  DeleteTodoError(String)

  // Form input messages
  TitleInputChanged(String)
  DescriptionInputChanged(String)
}

// Import Todo type from model
import frontend/model.{type Todo}
