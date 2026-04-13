import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string

/// Store record representing a boba store
pub type BobaStore {
  BobaStore(
    id: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Input for creating a new store
pub type CreateStoreInput {
  CreateStoreInput(
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
  )
}

/// Input for updating a store
pub type UpdateStoreInput {
  UpdateStoreInput(
    name: Option(String),
    address: Option(String),
    city: Option(String),
    phone: Option(String),
  )
}

/// Pagination parameters for listing stores
pub type PaginationParams {
  PaginationParams(limit: Int, offset: Int)
}

/// Paginated result for list operations
pub type PaginatedStores {
  PaginatedStores(
    stores: List(BobaStore),
    total: Int,
    limit: Int,
    offset: Int,
  )
}

/// Error types for store operations
pub type StoreError {
  StoreNotFound(String)
  StoreInvalidInput(String)
  StoreInternalError(String)
}

/// Sort field options
pub type SortBy {
  SortByName
  SortByCity
  SortByCreatedAt
}

/// Sort order options
pub type SortOrder {
  Asc
  Desc
}

/// List stores input parameters
pub type ListStoresInput {
  ListStoresInput(
    limit: Int,
    offset: Int,
    search: Option(String),
    sort_by: SortBy,
    sort_order: SortOrder,
  )
}

/// In-memory store state using Dict
pub opaque type StoreState {
  StoreState(stores: Dict(String, BobaStore), next_id: Int)
}

/// Create a new empty store state
pub fn new_state() -> StoreState {
  StoreState(stores: dict.new(), next_id: 1)
}

/// Generate a simple UUID-like string (reversible: can be replaced with proper UUID library)
fn generate_uuid(next_id: Int) -> String {
  "store-" <> pad_left(int_to_string(next_id), 8, "0")
}

/// Pad a string to minimum length with a character
fn pad_left(s: String, min_length: Int, pad_char: String) -> String {
  let current = string.length(s)
  case current >= min_length {
    True -> s
    False -> {
      let padding_count = min_length - current
      repeat_string(pad_char, padding_count) <> s
    }
  }
}

/// Repeat a string n times
fn repeat_string(s: String, n: Int) -> String {
  repeat_string_recursive(s, n, "")
}

fn repeat_string_recursive(s: String, n: Int, acc: String) -> String {
  case n <= 0 {
    True -> acc
    False -> repeat_string_recursive(s, n - 1, s <> acc)
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> int_to_string_recursive(n, "")
  }
}

fn int_to_string_recursive(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      int_to_string_recursive(n / 10, digit <> acc)
    }
  }
}

/// Generate current timestamp string
fn current_timestamp() -> String {
  "2026-04-12T00:00:00Z"
}

/// Create a new store
pub fn create(state: StoreState, input: CreateStoreInput) -> #(StoreState, BobaStore) {
  let id = generate_uuid(state.next_id)
  let timestamp = current_timestamp()

  let store = BobaStore(
    id: id,
    name: input.name,
    address: input.address,
    city: input.city,
    phone: input.phone,
    created_at: timestamp,
    updated_at: timestamp,
  )

  let new_stores = dict.insert(state.stores, id, store)
  let new_state = StoreState(stores: new_stores, next_id: state.next_id + 1)

  #(new_state, store)
}

/// Get a store by ID
pub fn get_by_id(state: StoreState, id: String) -> Result(BobaStore, StoreError) {
  case dict.get(state.stores, id) {
    Ok(store) -> Ok(store)
    Error(_) -> Error(StoreNotFound("Store not found: " <> id))
  }
}

/// List stores with pagination
pub fn list(state: StoreState, params: PaginationParams) -> PaginatedStores {
  let all_stores = dict.values(state.stores)
  let total = list.length(all_stores)

  let sorted_stores = list.sort(all_stores, fn(a, b) {
    string.compare(a.created_at, b.created_at)
  })

  let paginated = sorted_stores
    |> list.drop(params.offset)
    |> list.take(params.limit)

  PaginatedStores(
    stores: paginated,
    total: total,
    limit: params.limit,
    offset: params.offset,
  )
}

/// Update a store by ID
pub fn update(
  state: StoreState,
  id: String,
  input: UpdateStoreInput,
) -> #(StoreState, Result(BobaStore, StoreError)) {
  case dict.get(state.stores, id) {
    Error(_) -> #(state, Error(StoreNotFound("Store not found: " <> id)))
    Ok(existing) -> {
      let updated = BobaStore(
        id: existing.id,
        name: option.unwrap(input.name, existing.name),
        address: merge_option(input.address, existing.address),
        city: merge_option(input.city, existing.city),
        phone: merge_option(input.phone, existing.phone),
        created_at: existing.created_at,
        updated_at: current_timestamp(),
      )

      let new_stores = dict.insert(state.stores, id, updated)
      let new_state = StoreState(..state, stores: new_stores)

      #(new_state, Ok(updated))
    }
  }
}

/// Helper to merge optional update values
fn merge_option(new: Option(String), existing: Option(String)) -> Option(String) {
  case new {
    Some(value) -> Some(value)
    None -> existing
  }
}

/// Delete a store by ID
pub fn delete(state: StoreState, id: String) -> #(StoreState, Result(Nil, StoreError)) {
  case dict.get(state.stores, id) {
    Error(_) -> #(state, Error(StoreNotFound("Store not found: " <> id)))
    Ok(_) -> {
      let new_stores = dict.delete(state.stores, id)
      let new_state = StoreState(..state, stores: new_stores)
      #(new_state, Ok(Nil))
    }
  }
}

/// List all stores without pagination (for search)
pub fn list_all(state: StoreState) -> List(BobaStore) {
  dict.values(state.stores)
}

/// List stores with pagination, search, and sorting
pub fn list_with_params(state: StoreState, params: ListStoresInput) -> PaginatedStores {
  let all_stores = dict.values(state.stores)

  // Apply search filter if provided
  let filtered_stores = case params.search {
    None -> all_stores
    Some(search_term) -> filter_stores_by_search(all_stores, search_term)
  }

  let total = list.length(filtered_stores)

  // Apply sorting
  let sorted_stores = sort_stores(filtered_stores, params.sort_by, params.sort_order)

  // Apply pagination
  let paginated = sorted_stores
    |> list.drop(params.offset)
    |> list.take(params.limit)

  PaginatedStores(
    stores: paginated,
    total: total,
    limit: params.limit,
    offset: params.offset,
  )
}

/// Filter stores by search term (matches name or city, case-insensitive)
fn filter_stores_by_search(stores: List(BobaStore), search_term: String) -> List(BobaStore) {
  let trimmed_term = string.trim(search_term)
  case string.is_empty(trimmed_term) {
    True -> stores
    False -> {
      let lower_term = string.lowercase(trimmed_term)
      list.filter(stores, fn(store) {
        let name_match = string.contains(string.lowercase(store.name), lower_term)
        let city_match = case store.city {
          Some(city) -> string.contains(string.lowercase(city), lower_term)
          None -> False
        }
        name_match || city_match
      })
    }
  }
}

/// Sort stores by specified field and order
fn sort_stores(stores: List(BobaStore), sort_by: SortBy, sort_order: SortOrder) -> List(BobaStore) {
  let compare_fn: fn(BobaStore, BobaStore) -> order.Order = case sort_by {
    SortByName -> fn(a: BobaStore, b: BobaStore) { string.compare(a.name, b.name) }
    SortByCity -> fn(a: BobaStore, b: BobaStore) {
      let city_a = option.unwrap(a.city, "")
      let city_b = option.unwrap(b.city, "")
      string.compare(city_a, city_b)
    }
    SortByCreatedAt -> fn(a: BobaStore, b: BobaStore) { string.compare(a.created_at, b.created_at) }
  }

  let sorted = list.sort(stores, compare_fn)

  case sort_order {
    Asc -> sorted
    Desc -> list.reverse(sorted)
  }
}
