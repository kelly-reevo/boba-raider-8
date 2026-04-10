/// Application state

import frontend/pages/create_store_msg.{type CreateStoreState}

/// Page types for routing
pub type Page {
  HomePage
  CreateStorePage(CreateStoreState)
}

/// Root application model
pub type Model {
  Model(
    current_page: Page,
    error: String
  )
}

/// Initialize default model
pub fn default() -> Model {
  Model(
    current_page: HomePage,
    error: ""
  )
}

/// Initialize with CreateStorePage
pub fn with_create_store() -> Model {
  Model(
    current_page: CreateStorePage(create_store_msg.init()),
    error: ""
  )
}
