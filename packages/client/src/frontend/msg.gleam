/// Application messages for boba-raider-8 client

/// Form field types
pub type Field {
  NameField
  AddressField
  CityField
  PhoneField
}

/// Application messages
pub type Msg {
  // Legacy counter messages (preserved for existing functionality)
  Increment
  Decrement
  Reset

  // Create Store Form messages
  /// Update a form field value
  UpdateField(Field, String)

  /// Submit the form
  SubmitForm

  /// Form submission succeeded
  CreateStoreSuccess(store_id: String, name: String)

  /// Form submission failed
  CreateStoreError(error: String)

  /// Navigate to a page
  NavigateTo(String)

  /// Page changed
  PageChanged(String)
}
