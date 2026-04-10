/// Header component with conditional auth display

import frontend/model.{type Model}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{User}

/// Header component: logo, store list link, conditional auth display
/// Props: user: User | null (via Model)
/// Events: logout -> clear storage, redirect to /
pub fn header(model: Model) -> Element(Msg) {
  html.header([attribute.class("header")], [
    // Logo
    html.a([attribute.href("/"), attribute.class("logo")], [
      element.text("BobaRaider"),
    ]),

    // Navigation
    html.nav([attribute.class("nav")], [
      html.a([attribute.href("/stores"), attribute.class("nav-link")], [
        element.text("Store List"),
      ]),
    ]),

    // Auth section (conditional)
    html.div([attribute.class("auth-section")], [auth_links(model)]),
  ])
}

/// Render auth links based on authentication state
fn auth_links(model: Model) -> Element(Msg) {
  case model.user {
    // Logged in: show profile link + logout
    Some(User(username: name, ..)) ->
      html.div([attribute.class("auth-logged-in")], [
        html.a([attribute.href("/profile"), attribute.class("nav-link")], [
          element.text(name),
        ]),
        html.button(
          [event.on_click(msg.Logout), attribute.class("logout-button")],
          [element.text("Logout")],
        ),
      ])

    // Logged out: show login/register
    None ->
      html.div([attribute.class("auth-logged-out")], [
        html.a([attribute.href("/login"), attribute.class("nav-link")], [
          element.text("Login"),
        ]),
        html.a(
          [attribute.href("/register"), attribute.class("nav-link button")],
          [element.text("Register")],
        ),
      ])
  }
}
