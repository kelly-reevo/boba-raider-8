/// Toast notification component
/// Displays success/error/warning/info messages with auto-dismiss

import frontend/model.{type Toast, type ToastType, Error, Info, Success, Warning}
import frontend/msg.{type Msg, RemoveToast}
import gleam/int
import gleam/list
import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Get CSS class for toast type
fn toast_type_class(toast_type: ToastType) -> String {
  case toast_type {
    Success -> "toast toast--success"
    Error -> "toast toast--error"
    Warning -> "toast toast--warning"
    Info -> "toast toast--info"
  }
}

/// Get icon for toast type
fn toast_icon(toast_type: ToastType) -> String {
  case toast_type {
    Success -> "✓"
    Error -> "✕"
    Warning -> "⚠"
    Info -> "ℹ"
  }
}

/// Single toast notification element
pub fn toast_item(toast: Toast) -> Element(Msg) {
  html.div(
    [
      attr.class(toast_type_class(toast.toast_type)),
      attr.attribute("data-toast-id", toast.id),
      // Auto-dismiss duration passed as data attribute for CSS animation
      attr.attribute("data-duration", int.to_string(toast.duration_ms)),
    ],
    [
      html.span([attr.class("toast__icon")], [
        element.text(toast_icon(toast.toast_type)),
      ]),
      html.span([attr.class("toast__message")], [
        element.text(toast.message),
      ]),
      html.button(
        [
          attr.class("toast__close"),
          event.on_click(RemoveToast(toast.id)),
          attr.attribute("aria-label", "Close notification"),
        ],
        [element.text("×")],
      ),
      // Progress bar for auto-dismiss
      html.div([attr.class("toast__progress")], []),
    ],
  )
}

/// Container for all toast notifications (positioned fixed)
pub fn toast_container(toasts: List(Toast)) -> Element(Msg) {
  html.div(
    [
      attr.class("toast-container"),
      attr.attribute("role", "region"),
      attr.attribute("aria-live", "polite"),
      attr.attribute("aria-label", "Notifications"),
    ],
    list.map(toasts, toast_item),
  )
}
