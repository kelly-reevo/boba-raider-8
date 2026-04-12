/// Application messages

pub type Msg {
  // Counter messages (legacy demo)
  Increment
  Decrement
  Reset

  // Todo deletion messages
  DeleteTodoClick(String)
  DeleteTodoSuccess(String)
  DeleteTodoFailed(String)
  ConfirmDelete(String)
  CancelDelete
}
