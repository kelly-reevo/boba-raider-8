/// Application messages

import shared

pub type Msg {
  // Form input messages
  TitleChanged(String)
  DescriptionChanged(String)

  // Form submission
  SubmitForm
  SubmitSuccess(shared.Todo)
  SubmitError(String)

  // Todo list management
  TodosLoaded(List(shared.Todo))
  TodosLoadError(String)

  // Clear error
  ClearError
}
