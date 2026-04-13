/// Application messages for todo management

import frontend/model.{type Todo, type Filter}

/// Messages that can be sent to update the application
pub type Msg {
  // Todo loading
  LoadTodos
  TodosLoaded(List(Todo))
  TodosLoadFailed(String)

  // Filter changes
  SetFilter(Filter)

  // Form input changes
  SetTitle(String)
  SetDescription(String)
  SetPriority(String)

  // Todo creation
  SubmitForm
  TodoCreated(Todo)
  TodoCreateFailed(String)

  // Todo deletion
  DeleteTodo(String)
  TodoDeleted(String)
  TodoDeleteFailed(String)

  // Todo toggle/update with optimistic update support
  ToggleTodo(id: String, completed: Bool)
  ToggleTodoSuccess(item: Todo)
  ToggleTodoError(id: String, previous_state: Bool, error: String)
  TodoUpdated(Todo)
  TodoUpdateFailed(String)
}
