/// Application messages for routing, auth, and form handling

import frontend/pages/create_store_msg.{type Msg as CreateStoreMsg}

/// Root application messages
pub type Msg {
  // Navigation
  NavigateToCreateStore
  NavigateToHome

  // Page-specific messages
  CreateStoreMsg(CreateStoreMsg)
}
