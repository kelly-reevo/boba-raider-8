/// Application messages for todo management

import frontend/model.{type Todo, type Filter}

/// Messages that can be sent to update the application
pub type Msg {
  // Todo loading
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

  // Todo updates
  ToggleTodo(String)
  TodoUpdated(Todo)
  TodoUpdateFailed(String)
}
