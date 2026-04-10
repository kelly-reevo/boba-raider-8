import frontend/model.{type ToastType}

/// Application messages

pub type Msg {
  Increment
  Decrement
  Reset

  // Toast notifications
  ShowToast(message: String, toast_type: ToastType, duration_ms: Int)
  RemoveToast(toast_id: String)
  ClearAllToasts

  // Global error handling
  SetGlobalError(error: String)
  ClearGlobalError

  // API error handling
  ApiErrorOccurred(operation: String, details: String)
}
