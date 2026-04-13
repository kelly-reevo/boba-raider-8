/// Store List Messages - User actions and effects for the store list page

import frontend/store_list/model.{type SortBy, type SortOrder, type Store}

/// Messages for the store list page
pub type Msg {
  // Search
  SearchInputChanged(String)
  DebouncedSearchTriggered

  // Pagination
  PageChanged(Int)
  NextPage
  PrevPage

  // Sorting
  SortByChanged(SortBy)
  SortOrderChanged(SortOrder)

  // API responses
  StoresLoaded(List(Store), Int)
  StoresLoadFailed(String)

  // Timer for debounce
  SearchTimerTicked
}
