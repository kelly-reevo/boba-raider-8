/// Main view with routing and navigation

import frontend/model.{type Model, LoggedIn, LoggedOut, AuthLoading}
import frontend/msg.{type Msg, type Route, Home, Login, Register, NavigateTo, LogoutRequested}
import frontend/pages/auth.{login_page, register_page, loading_spinner}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function - renders based on current route
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    navigation_bar(model),
    html.main([attribute.class("main-content")], [
      case model.auth {
        // Show loading while checking auth state
        AuthLoading -> loading_spinner()
        _ -> render_route(model)
      },
    ]),
  ])
}

/// Render the appropriate page based on current route
fn render_route(model: Model) -> Element(Msg) {
  case model.route {
    route if route == Home -> home_page(model)
    route if route == Login -> login_page(model)
    route if route == Register -> register_page(model)
    _ -> home_page(model)
  }
}

/// Navigation bar with auth-aware links
fn navigation_bar(model: Model) -> Element(Msg) {
  html.nav([attribute.class("navbar")], [
    html.div([attribute.class("nav-brand")], [
      html.a(
        [attribute.href("#/"), event.on_click(NavigateTo(Home))],
        [element.text("BobaRaider")],
      ),
    ]),
    html.div([attribute.class("nav-links")], [
      case model.auth {
        LoggedIn(user, _) -> {
          // Logged in: show user name and logout
          html.div([attribute.class("auth-section")], [
            html.span([attribute.class("user-name")], [
              element.text(user.username),
            ]),
            html.button(
              [
                attribute.class("btn btn-secondary"),
                event.on_click(LogoutRequested),
              ],
              [element.text("Logout")],
            ),
          ])
        }
        _ -> {
          // Not logged in: show login/register links
          html.div([attribute.class("auth-section")], [
            html.a(
              [
                attribute.href("#/login"),
                event.on_click(NavigateTo(Login)),
                attribute.class("nav-link"),
              ],
              [element.text("Sign In")],
            ),
            html.a(
              [
                attribute.href("#/register"),
                event.on_click(NavigateTo(Register)),
                attribute.class("nav-link btn btn-primary"),
              ],
              [element.text("Sign Up")],
            ),
          ])
        }
      },
    ]),
  ])
}

/// Home page component
fn home_page(model: Model) -> Element(Msg) {
  html.div([attribute.class("home-page")], [
    case model.auth {
      LoggedIn(user, _) -> {
        // Authenticated home
        html.div([attribute.class("welcome-section")], [
          html.h1([], [element.text("Welcome back, " <> user.username <> "!")]),
          html.p([], [
            element.text("You are successfully authenticated. Your session is stored in localStorage."),
          ]),
          html.div([attribute.class("user-card")], [
            html.h3([], [element.text("Your Profile")]),
            html.p([], [element.text("ID: " <> user.id)]),
            html.p([], [element.text("Email: " <> user.email)]),
            html.p([], [element.text("Username: " <> user.username)]),
          ]),
        ])
      }
      _ -> {
        // Unauthenticated home
        html.div([attribute.class("welcome-section")], [
          html.h1([], [element.text("Welcome to BobaRaider")]),
          html.p([], [
            element.text("Please sign in or create an account to continue."),
          ]),
          html.div([attribute.class("cta-buttons")], [
            html.a(
              [
                attribute.href("#/login"),
                event.on_click(NavigateTo(Login)),
                attribute.class("btn btn-primary"),
              ],
              [element.text("Sign In")],
            ),
            html.a(
              [
                attribute.href("#/register"),
                event.on_click(NavigateTo(Register)),
                attribute.class("btn btn-secondary"),
              ],
              [element.text("Create Account")],
            ),
          ]),
        ])
      }
    },
  ])
}
