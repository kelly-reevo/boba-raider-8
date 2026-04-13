/// Application messages

pub type Msg {
  // Counter messages
  Increment
  Decrement
  Reset

  // Create Drink Form messages
  CreateDrinkFormFieldUpdate(field: FormField, value: String)
  CreateDrinkFormSubmit
  CreateDrinkFormSubmitSuccess(drink_id: String)
  CreateDrinkFormSubmitError(error: String)
}

/// Form fields that can be updated
pub type FormField {
  StoreId
  DrinkName
  Description
  BaseTeaType
  Price
}
