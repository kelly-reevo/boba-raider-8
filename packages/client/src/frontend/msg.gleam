/// Application messages

import shared.{type Store, type StoreInput, type AppError, type User}

pub type Msg {
  // Original counter messages
  Increment
  Decrement
  Reset

  // Navigation
  Navigate(String)
  RouteChanged(String)

  // Edit Store Page messages
  EditStoreMsg(EditStoreMsg)
}

/// Messages specific to edit store form
pub type EditStoreMsg {
  UpdateName(String)
  UpdateDescription(String)
  UpdateAddress(String)
  UpdatePhone(String)
  UpdateEmail(String)
  SubmitForm
  StoreLoaded(Result(Store, AppError))
  StoreUpdated(Result(Store, AppError))
  CurrentUserLoaded(Result(User, AppError))
  CancelEdit
  ResetForm
}
