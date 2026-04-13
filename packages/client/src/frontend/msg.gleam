/// Application messages for todo list

import frontend/model.{type Filter}
import shared.{type Todo, type Priority}

/// Message type for MVU pattern
pub type Msg {
  // Data loading messages
  FetchTodos
  TodosLoaded(List(Todo))
  TodosLoadError(String)
  RetryFetch

  // Filter messages - support both string-based and Filter type
  SetFilter(Filter)
  FilterChanged(String)
  TodosFetched(List(Todo))
  FetchError(String)

  // Form field update messages
  TitleChanged(String)
  DescriptionChanged(String)
  PriorityChanged(Priority)

  // Form submission messages
  SubmitForm
  CreateTodoSucceeded(Todo)
  CreateTodoFailed(String)

  // Todo list refresh messages
  RefreshTodos
  TodosRefreshed(List(Todo))
  TodosRefreshFailed(String)

  // Delete todo messages
  DeleteTodo(id: String)
  Deleted(id: String)
  DeleteError(message: String)

  // Toggle completion messages
  ToggleTodo(id: String, completed: Bool)
  TodoToggledOk(Todo)
  TodoToggledError(id: String, original_completed: Bool)

  // Error handling
  DismissError
  SetError(String)
}
