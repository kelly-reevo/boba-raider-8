/// Application messages including error state handling

import frontend/model.{type ApiError, type FieldError, type Todo}

/// User actions and application events
pub type Msg {
  // Todo list actions
  LoadTodos
  LoadTodosSuccess(List(Todo))
  LoadTodosError(ApiError)

  // Form actions
  SubmitTodo
  SubmitTodoSuccess(Todo)
  SubmitTodoError(ApiError)
  UpdateTitle(String)
  UpdateDescription(String)
  UpdatePriority(String)

  // Todo actions
  DeleteTodo(String)
  DeleteTodoSuccess(String)
  DeleteTodoError(ApiError)
  EditTodo(String)
  EditTodoSuccess(Todo)
  EditTodoError(ApiError)

  // Error handling actions
  ClearErrors
  RetryLoadTodos
}
