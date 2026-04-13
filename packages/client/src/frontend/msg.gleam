/// Application messages for todo list

import frontend/model.{type Filter}
import shared.{type Todo}

/// Message type for MVU pattern
pub type Msg {
  /// Initial fetch on app startup
  FetchTodos
  /// Todos successfully loaded
  TodosLoaded(List(Todo))
  /// Error loading todos
  TodosLoadError(String)
  /// Change the current filter
  SetFilter(Filter)
  /// Retry fetching after error
  RetryFetch
}
