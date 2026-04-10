/// Error Boundary component
/// Catches and displays global errors with recovery options

import frontend/model.{type Model}
import frontend/msg.{type Msg, ClearAllToasts, ClearGlobalError}
import gleam/option.{None, Some}
import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Error boundary view - shows global error if present
pub fn error_boundary(model: Model, children: List(Element(Msg))) -> Element(Msg) {
  case model.global_error {
    None -> html.div([attr.class("error-boundary__content")], children)
    Some(error) -> error_overlay(error)
  }
}

/// Full-screen error overlay with recovery actions
fn error_overlay(error: String) -> Element(Msg) {
  html.div(
    [
      attr.class("error-boundary"),
      attr.attribute("role", "alert"),
      attr.attribute("aria-live", "assertive"),
    ],
    [
      html.div([attr.class("error-boundary__overlay")], [
        html.div([attr.class("error-boundary__panel")], [
          html.h2([attr.class("error-boundary__title")], [
            element.text("Something went wrong"),
          ]),
          html.div([attr.class("error-boundary__icon")], [
            element.text("⚠"),
          ]),
          html.p([attr.class("error-boundary__message")], [
            element.text(error),
          ]),
          html.div([attr.class("error-boundary__actions")], [
            html.button(
              [
                attr.class("error-boundary__retry"),
                event.on_click(ClearGlobalError),
              ],
              [element.text("Dismiss Error")],
            ),
            html.button(
              [
                attr.class("error-boundary__clear"),
                event.on_click(ClearAllToasts),
              ],
              [element.text("Clear All Notifications")],
            ),
          ]),
        ]),
      ]),
      // Render children dimmed behind overlay
      html.div(
        [
          attr.class("error-boundary__content error-boundary__content--dimmed"),
          // Prevent interaction with background while error is shown
          attr.style("pointer-events", "none"),
        ],
        [],
      ),
    ],
  )
}

/// Inline error display for non-blocking errors
pub fn inline_error(error: String) -> Element(Msg) {
  html.div(
    [
      attr.class("inline-error"),
      attr.attribute("role", "alert"),
    ],
    [
      html.span([attr.class("inline-error__icon")], [element.text("✕")]),
      html.span([attr.class("inline-error__text")], [element.text(error)]),
    ],
  )
}

/// Error placeholder for empty/error states
pub fn error_state(title: String, message: String) -> Element(Msg) {
  html.div(
    [attr.class("error-state")],
    [
      html.div([attr.class("error-state__icon")], [element.text("⚠")]),
      html.h3([attr.class("error-state__title")], [element.text(title)]),
      html.p([attr.class("error-state__message")], [element.text(message)]),
    ],
  )
}
