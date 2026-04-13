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

  // Filter messages
  SetFilter(Filter)

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

  // Error handling
  DismissError
}
