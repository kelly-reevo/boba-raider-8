import gleam/option.{type Option, None}

/// Application state

pub type ToastType {
  Success
  Error
  Warning
  Info
}

pub type Toast {
  Toast(id: String, message: String, toast_type: ToastType, duration_ms: Int)
}

pub type Model {
  Model(
    count: Int,
    global_error: Option(String),
    toasts: List(Toast),
    next_toast_id: Int,
  )
}

pub fn default() -> Model {
  Model(count: 0, global_error: None, toasts: [], next_toast_id: 1)
}
