import frontend/model.{type Model, LoginPage, ProfilePage, RegisterPage}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    nav_bar(model),
    case model.loading {
      True -> loading_view()
      False ->
        case model.page {
          LoginPage -> login_view(model)
          RegisterPage -> register_view(model)
          ProfilePage -> profile_view(model)
        }
    },
  ])
}

fn nav_bar(model: Model) -> Element(Msg) {
  html.nav([attribute.class("nav")], case model.token {
    None -> [
      html.button([event.on_click(msg.GoToLogin), attribute.class("nav-link")], [
        element.text("Login"),
      ]),
      html.button(
        [event.on_click(msg.GoToRegister), attribute.class("nav-link")],
        [element.text("Register")],
      ),
    ]
    Some(_) -> [
      html.button(
        [event.on_click(msg.GoToProfile), attribute.class("nav-link")],
        [element.text("Profile")],
      ),
      html.button([event.on_click(msg.Logout), attribute.class("nav-link")], [
        element.text("Logout"),
      ]),
    ]
  })
}

fn error_banner(error: String) -> Element(Msg) {
  case error {
    "" -> element.none()
    msg -> html.div([attribute.class("error")], [element.text(msg)])
  }
}

fn loading_view() -> Element(Msg) {
  html.div([attribute.class("loading")], [element.text("Loading...")])
}

fn login_view(model: Model) -> Element(Msg) {
  html.div([attribute.class("auth-form")], [
    html.h2([], [element.text("Login")]),
    error_banner(model.error),
    html.form([event.on_submit(fn(_) { msg.SubmitLogin })], [
      html.div([attribute.class("field")], [
        html.label([], [element.text("Email")]),
        html.input([
          attribute.type_("email"),
          attribute.value(model.email),
          attribute.placeholder("Email"),
          attribute.attribute("required", "true"),
          event.on_input(msg.SetEmail),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([], [element.text("Password")]),
        html.input([
          attribute.type_("password"),
          attribute.value(model.password),
          attribute.placeholder("Password"),
          attribute.attribute("required", "true"),
          event.on_input(msg.SetPassword),
        ]),
      ]),
      html.button([attribute.type_("submit"), attribute.class("btn-primary")], [
        element.text("Login"),
      ]),
    ]),
    html.p([attribute.class("auth-switch")], [
      element.text("Don't have an account? "),
      html.button(
        [event.on_click(msg.GoToRegister), attribute.class("link-btn")],
        [element.text("Register")],
      ),
    ]),
  ])
}

fn register_view(model: Model) -> Element(Msg) {
  html.div([attribute.class("auth-form")], [
    html.h2([], [element.text("Register")]),
    error_banner(model.error),
    html.form([event.on_submit(fn(_) { msg.SubmitRegister })], [
      html.div([attribute.class("field")], [
        html.label([], [element.text("Username")]),
        html.input([
          attribute.type_("text"),
          attribute.value(model.username),
          attribute.placeholder("Username"),
          attribute.attribute("required", "true"),
          event.on_input(msg.SetUsername),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([], [element.text("Email")]),
        html.input([
          attribute.type_("email"),
          attribute.value(model.email),
          attribute.placeholder("Email"),
          attribute.attribute("required", "true"),
          event.on_input(msg.SetEmail),
        ]),
      ]),
      html.div([attribute.class("field")], [
        html.label([], [element.text("Password")]),
        html.input([
          attribute.type_("password"),
          attribute.value(model.password),
          attribute.placeholder("Password"),
          attribute.attribute("required", "true"),
          event.on_input(msg.SetPassword),
        ]),
      ]),
      html.button([attribute.type_("submit"), attribute.class("btn-primary")], [
        element.text("Register"),
      ]),
    ]),
    html.p([attribute.class("auth-switch")], [
      element.text("Already have an account? "),
      html.button(
        [event.on_click(msg.GoToLogin), attribute.class("link-btn")],
        [element.text("Login")],
      ),
    ]),
  ])
}

fn profile_view(model: Model) -> Element(Msg) {
  html.div([attribute.class("profile")], [
    html.h2([], [element.text("Profile")]),
    error_banner(model.error),
    case model.user {
      None ->
        html.p([attribute.class("empty-state")], [
          element.text("No profile data available."),
        ])
      Some(user) ->
        html.div([attribute.class("profile-card")], [
          html.div([attribute.class("profile-field")], [
            html.strong([], [element.text("Username: ")]),
            element.text(user.username),
          ]),
          html.div([attribute.class("profile-field")], [
            html.strong([], [element.text("Email: ")]),
            element.text(user.email),
          ]),
          html.div([attribute.class("profile-field")], [
            html.strong([], [element.text("ID: ")]),
            element.text(user.id),
          ]),
        ])
    },
  ])
}
