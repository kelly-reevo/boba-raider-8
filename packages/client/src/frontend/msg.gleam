import frontend/model.{type Filter}
import shared.{type Todo}

/// Application messages
pub type Msg {
  // Filter control messages
  SetFilter(Filter)

  // Todo data messages
  TodosLoaded(List(Todo))
  TodoAdded(Todo)

  // Legacy counter messages (to be removed)
  Increment
  Decrement
  Reset
}
