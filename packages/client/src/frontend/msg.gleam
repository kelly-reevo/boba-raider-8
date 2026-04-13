/// Application messages

import shared.{type Todo, type Priority}

/// Messages that can be sent to update the application
pub type Msg {
  // Form field update messages
  TitleChanged(String)
  DescriptionChanged(String)
  PriorityChanged(Priority)

  // Form submission messages
  SubmitForm
  CreateTodoSucceeded(Todo)
  CreateTodoFailed(String)

  // Todo list messages
  RefreshTodos
  TodosRefreshed(List(Todo))
  TodosRefreshFailed(String)
}
