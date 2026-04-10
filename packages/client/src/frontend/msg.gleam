/// Application messages

import shared.{type Store, type SortOption, type StoreFilters}

/// Messages for counter feature (legacy)
pub type CounterMsg {
  Increment
  Decrement
  Reset
}

/// Messages for store list page
pub type StoreListMsg {
  LoadStores
  StoresLoaded(Result(List(Store), String))
  SearchChanged(String)
  LocationChanged(String)
  SortChanged(SortOption)
  PageChanged(Int)
  RetryLoad
}

/// Main application message type
pub type Msg {
  Counter(CounterMsg)
  StoreList(StoreListMsg)
}
