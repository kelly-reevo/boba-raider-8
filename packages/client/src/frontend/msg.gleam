/// Application messages

import shared.{type TeaType}

/// Form-related messages
pub type Msg {
  Increment
  Decrement
  Reset

  // Form visibility
  OpenCreateDrinkForm(store_id: String)
  CloseCreateDrinkForm

  // Form field updates
  UpdateDrinkName(String)
  UpdateTeaType(TeaType)
  UpdatePrice(String)
  UpdateDescription(String)
  UpdateImageFile(String)
  ToggleIsSignature

  // API interactions
  SubmitDrinkForm
  ImageUploaded(Result(String, String))
  DrinkCreated(Result(String, String))

  // Form state
  ResetForm
}
