/// Application messages

/// Messages for the update loop
pub type Msg {
  // Delete todo flow
  DeleteTodo(id: String)
  Deleted(id: String)
  DeleteError(message: String)

  // Error handling
  DismissError
}
