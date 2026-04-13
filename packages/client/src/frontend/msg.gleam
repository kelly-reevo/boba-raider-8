/// Application messages

import frontend/model.{type Filter}
import gleam/dict.{type Dict}
import shared.{type Todo, type Priority}

/// API response types
pub type ApiError {
  NetworkError
  ServerError(status: Int)
  ValidationError(field_errors: Dict(String, String))
}

pub type Msg {
  // Form interactions
  FormTitleChanged(String)
  FormDescriptionChanged(String)
  FormPriorityChanged(Priority)
  FormSubmit
  FormReset

  // Todo actions
  FetchTodos
  CreateTodo(title: String, description: String, priority: Priority)
  UpdateTodo(id: String, title: String, description: String, completed: Bool)
  DeleteTodo(id: String)
  ToggleTodo(id: String, completed: Bool)

  // Filter actions
  FilterChanged(filter: Filter)

  // API responses
  FetchTodosSuccess(todos: List(Todo))
  FetchTodosError(error: ApiError)
  CreateTodoSuccess(todo_item: Todo)
  CreateTodoError(error: ApiError)
  UpdateTodoSuccess(todo_item: Todo)
  UpdateTodoError(error: ApiError)
  DeleteTodoSuccess(id: String)
  DeleteTodoError(error: ApiError, id: String)

  // Error handling
  RetryAction
  ClearError
  DismissFieldError(field: String)
}
