/// Application messages

import frontend/model.{type Filter}
import shared.{type Todo}

/// Message types for the MVU architecture
pub type Msg {
  // Filter control messages
  FilterChanged(Filter)
  TodosLoaded(List(Todo))
  TodosLoadFailed(String)

  // Todo creation messages
  TodoCreated(Todo)
  TodoCreateFailed(String)
}
