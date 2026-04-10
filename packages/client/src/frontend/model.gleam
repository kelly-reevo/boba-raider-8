/// Application state with routing and authentication support

import shared.{
  type Store, type StoreInput, type User, type StoreValidationErrors,
  type Option, Some, None,
}

pub type Model {
  Model(
    // Current user (for authorization guard)
    current_user: Option(User),
    // Page state
    page: Page,
    // Navigation
    route: Route,
  )
}

pub type Route {
  Home
  StoreList
  StoreDetail(String)  // store_id
  CreateStore
  EditStore(String)    // store_id
  NotFound
}

pub type Page {
  // Counter page (original)
  CounterPage(count: Int, error: String)
  // Store pages
  EditStorePage(EditStoreState)
  // Other pages would go here
  EmptyPage
}

/// State for the edit store form
pub type EditStoreState {
  EditStoreState(
    store_id: String,
    // Form data
    input: StoreInput,
    validation_errors: StoreValidationErrors,
    // Page lifecycle states
    loading: Bool,
    saving: Bool,
    load_error: Option(String),
    save_error: Option(String),
    // Original store data (for comparison/authorization)
    original_store: Option(Store),
    // Success redirect flag
    redirect_to: Option(String),
  )
}

/// States an edit form can be in:
/// 1. Loading - fetching store data
/// 2. Unauthorized - user is not the creator
/// 3. Error - failed to load store
/// 4. Ready - form loaded, waiting for user input
/// 5. Saving - submitting changes
/// 6. Success - redirecting

pub fn default() -> Model {
  Model(
    current_user: None,
    page: CounterPage(0, ""),
    route: Home,
  )
}

/// Initialize model for edit store page
pub fn init_edit_store_page(store_id: String) -> Model {
  Model(
    current_user: None,
    page: EditStorePage(init_edit_store_state(store_id)),
    route: EditStore(store_id),
  )
}

fn init_edit_store_state(store_id: String) -> EditStoreState {
  EditStoreState(
    store_id: store_id,
    input: shared.default_store_input(),
    validation_errors: shared.default_validation_errors(),
    loading: True,
    saving: False,
    load_error: None,
    save_error: None,
    original_store: None,
    redirect_to: None,
  )
}

/// Check if user is authorized to edit the store
pub fn can_edit_store(user: Option(User), store: Option(Store)) -> Bool {
  case user, store {
    Some(u), Some(s) -> u.id == s.created_by
    _, _ -> False
  }
}

/// Get current edit store state if on edit page
pub fn get_edit_store_state(model: Model) -> Option(EditStoreState) {
  case model.page {
    EditStorePage(state) -> Some(state)
    _ -> None
  }
}

/// Update the edit store page state
pub fn update_edit_store_state(
  model: Model,
  updater: fn(EditStoreState) -> EditStoreState,
) -> Model {
  case model.page {
    EditStorePage(state) -> {
      Model(..model, page: EditStorePage(updater(state)))
    }
    _ -> model
  }
}
