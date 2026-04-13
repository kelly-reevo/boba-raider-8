/// Application messages for todo management with empty state UI

import frontend/model.{type Filter}
import gleam/option.{type Option}
import shared.{type Todo, type Priority}

/// Messages that can be sent to update the application state
pub type Msg {
  // Todo list lifecycle
  LoadTodos
  TodosLoaded(List(Todo))
  TodosLoadFailed(String)

  // Todo creation
  CreateTodo
  TodoCreated(Todo)
  TodoCreateFailed(String)
  UpdateNewTodoTitle(String)
  UpdateNewTodoDescription(String)

  // Todo updates
  ToggleTodo(String, Bool)
  TodoUpdated(Todo)
  TodoUpdateFailed(String)

  // Todo deletion
  DeleteTodo(String)
  TodoDeleted(String)
  TodoDeleteFailed(String)

  // Filter selection
  SetFilter(Filter)

  // Form handling
  SubmitNewTodo
}
