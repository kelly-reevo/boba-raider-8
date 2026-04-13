/// Application messages including error state handling AND filter support

import frontend/model.{type ApiError, type Filter, type Todo}

/// User actions and application events
pub type Msg {
  // Legacy counter messages (keep for compatibility)
  Increment
  Decrement
  Reset

  // Todo list actions
  LoadTodos
  LoadTodosSuccess(List(Todo))
  LoadTodosError(ApiError)

  // Filter actions
  FilterChanged(Filter)

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

  // Result wrapper for todos loaded with filter
  TodosLoaded(Result(List(Todo), String))
}
