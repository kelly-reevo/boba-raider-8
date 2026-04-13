/// Store List Model - Application state for the store list page

/// Store record representing a boba store from API
pub type Store {
  Store(
    id: String,
    name: String,
    city: String,
    drink_count: Int,
  )
}

/// Pagination state
pub type Pagination {
  Pagination(
    limit: Int,
    offset: Int,
    total: Int,
  )
}

/// Loading state for async operations
pub type LoadingState {
  Idle
  Loading
  Loaded
  Error(String)
}

/// Sort options
pub type SortBy {
  SortByName
  SortByCity
}

pub type SortOrder {
  Asc
  Desc
}

/// Main model for the store list page
pub type Model {
  Model(
    // Data
    stores: List(Store),
    // Search
    search_term: String,
    debounced_search: String,
    // Pagination
    pagination: Pagination,
    // Loading state
    loading_state: LoadingState,
    // Sorting
    sort_by: SortBy,
    sort_order: SortOrder,
    // Debounce timer tracking
    pending_search_timer: Int,
  )
}

/// Default/initial model state
pub fn default() -> Model {
  Model(
    stores: [],
    search_term: "",
    debounced_search: "",
    pagination: Pagination(limit: 20, offset: 0, total: 0),
    loading_state: Idle,
    sort_by: SortByName,
    sort_order: Asc,
    pending_search_timer: 0,
  )
}

/// Calculate total pages from pagination
pub fn total_pages(pagination: Pagination) -> Int {
  case pagination.total <= 0 {
    True -> 1
    False -> {
      let pages = pagination.total / pagination.limit
      case pagination.total % pagination.limit > 0 {
        True -> pages + 1
        False -> pages
      }
    }
  }
}

/// Calculate current page number (1-indexed)
pub fn current_page(pagination: Pagination) -> Int {
  { pagination.offset / pagination.limit } + 1
}

/// Check if there's a next page
pub fn has_next_page(pagination: Pagination) -> Bool {
  let total = total_pages(pagination)
  let current = current_page(pagination)
  current < total
}

/// Check if there's a previous page
pub fn has_prev_page(pagination: Pagination) -> Bool {
  current_page(pagination) > 1
}
