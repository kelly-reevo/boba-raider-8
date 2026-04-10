/// Authentication pages: Login and Register components

import frontend/model.{type Model}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Login page component - handles all states: initial, loading, error
pub fn login_page(model: Model) -> Element(Msg) {
  let form = model.login_form

  html.div([attribute.class("auth-page login-page")], [
    html.div([attribute.class("auth-container")], [
      html.h1([], [element.text("Sign In")]),

      // Error display
      error_banner(form.error),

      // Login form
      html.form(
        [
          attribute.class("auth-form"),
          event.on_submit(fn(_) { msg.LoginSubmitted }),
        ],
        [
          // Email field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("email")], [element.text("Email")]),
            html.input([
              attribute.id("email"),
              attribute.type_("email"),
              attribute.placeholder("your@email.com"),
              attribute.value(form.email),
              attribute.disabled(form.is_loading),
              event.on_input(msg.LoginEmailChanged),
            ]),
          ]),

          // Password field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("password")], [element.text("Password")]),
            html.input([
              attribute.id("password"),
              attribute.type_("password"),
              attribute.placeholder("Enter your password"),
              attribute.value(form.password),
              attribute.disabled(form.is_loading),
              event.on_input(msg.LoginPasswordChanged),
            ]),
          ]),

          // Submit button with loading state
          submit_button("Sign In", form.is_loading),
        ],
      ),

      // Link to register
      html.div([attribute.class("auth-links")], [
        element.text("Don't have an account? "),
        html.a(
          [attribute.href("#/register"), event.on_click(msg.NavigateTo(msg.Register))],
          [element.text("Sign up")],
        ),
      ]),
    ]),
  ])
}

/// Register page component - handles all states: initial, loading, error
pub fn register_page(model: Model) -> Element(Msg) {
  let form = model.register_form

  html.div([attribute.class("auth-page register-page")], [
    html.div([attribute.class("auth-container")], [
      html.h1([], [element.text("Create Account")]),

      // Error display
      error_banner(form.error),

      // Register form
      html.form(
        [
          attribute.class("auth-form"),
          event.on_submit(fn(_) { msg.RegisterSubmitted }),
        ],
        [
          // Username field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("username")], [element.text("Username")]),
            html.input([
              attribute.id("username"),
              attribute.type_("text"),
              attribute.placeholder("Choose a username"),
              attribute.value(form.username),
              attribute.disabled(form.is_loading),
              event.on_input(msg.RegisterUsernameChanged),
            ]),
          ]),

          // Email field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("email")], [element.text("Email")]),
            html.input([
              attribute.id("email"),
              attribute.type_("email"),
              attribute.placeholder("your@email.com"),
              attribute.value(form.email),
              attribute.disabled(form.is_loading),
              event.on_input(msg.RegisterEmailChanged),
            ]),
          ]),

          // Password field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("password")], [element.text("Password")]),
            html.input([
              attribute.id("password"),
              attribute.type_("password"),
              attribute.placeholder("At least 8 characters"),
              attribute.value(form.password),
              attribute.disabled(form.is_loading),
              event.on_input(msg.RegisterPasswordChanged),
            ]),
            html.small([attribute.class("form-hint")], [
              element.text("Must be at least 8 characters"),
            ]),
          ]),

          // Confirm password field
          html.div([attribute.class("form-group")], [
            html.label([attribute.for("confirm-password")], [
              element.text("Confirm Password"),
            ]),
            html.input([
              attribute.id("confirm-password"),
              attribute.type_("password"),
              attribute.placeholder("Re-enter your password"),
              attribute.value(form.confirm_password),
              attribute.disabled(form.is_loading),
              event.on_input(msg.RegisterConfirmPasswordChanged),
            ]),
          ]),

          // Submit button with loading state
          submit_button("Create Account", form.is_loading),
        ],
      ),

      // Link to login
      html.div([attribute.class("auth-links")], [
        element.text("Already have an account? "),
        html.a(
          [attribute.href("#/login"), event.on_click(msg.NavigateTo(msg.Login))],
          [element.text("Sign in")],
        ),
      ]),
    ]),
  ])
}

/// Error banner component - displays when there's an error
fn error_banner(error: String) -> Element(Msg) {
  case error {
    "" -> html.div([attribute.class("error-banner hidden")], [])
    _ ->
      html.div([attribute.class("error-banner")], [
        html.span([attribute.class("error-icon")], [element.text("⚠")]),
        html.span([attribute.class("error-message")], [element.text(error)]),
      ])
  }
}

/// Submit button with loading state
fn submit_button(label: String, is_loading: Bool) -> Element(Msg) {
  case is_loading {
    True ->
      html.button(
        [
          attribute.type_("submit"),
          attribute.class("btn btn-primary btn-loading"),
          attribute.disabled(True),
        ],
        [
          html.span([attribute.class("spinner")], []),
          element.text("Loading..."),
        ],
      )
    False ->
      html.button(
        [
          attribute.type_("submit"),
          attribute.class("btn btn-primary"),
        ],
        [element.text(label)],
      )
  }
}

/// Loading state component
pub fn loading_spinner() -> Element(Msg) {
  html.div([attribute.class("loading-container")], [
    html.div([attribute.class("spinner-large")], []),
    html.p([], [element.text("Loading...")]),
  ])
}

/// Empty state component (for auth forms when initialized)
pub fn empty_state() -> Element(Msg) {
  html.div([attribute.class("empty-state")], [])
}
