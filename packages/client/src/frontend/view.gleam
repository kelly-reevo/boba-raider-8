import gleam/float
import gleam/int
import gleam/list
import gleam/string
import frontend/model.{
  type Model, Failed, Loaded, Loading, LoginPage, ProfilePage, RegisterPage,
  StoreListPage,
}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Store}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    nav_bar(model),
    case model.loading {
      True -> loading_spinner()
      False ->
        case model.page {
          LoginPage -> login_view(model)
          RegisterPage -> register_view(model)
          ProfilePage -> profile_view(model)
          StoreListPage ->
            html.div([], [
              search_bar(model.search_query),
              store_content(model),
            ])
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
      html.button(
        [event.on_click(msg.GoToStoreList), attribute.class("nav-link")],
        [element.text("Stores")],
      ),
    ]
    Some(_) -> [
      html.button(
        [event.on_click(msg.GoToProfile), attribute.class("nav-link")],
        [element.text("Profile")],
      ),
      html.button(
        [event.on_click(msg.GoToStoreList), attribute.class("nav-link")],
        [element.text("Stores")],
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

fn loading_spinner() -> Element(Msg) {
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

// Store listing views

fn search_bar(query: String) -> Element(Msg) {
  html.div([attribute.class("search-bar")], [
    html.input([
      attribute.type_("text"),
      attribute.placeholder("Search stores..."),
      attribute.value(query),
      event.on_input(msg.UserUpdatedSearch),
    ]),
  ])
}

fn store_content(model: Model) -> Element(Msg) {
  case model.store_load_state {
    Loading -> store_loading_view()
    Failed(err) -> error_view(err)
    Loaded -> {
      let filtered = filter_stores(model.stores, model.search_query)
      case filtered {
        [] -> empty_view(model.search_query)
        stores -> store_grid(stores)
      }
    }
  }
}

fn store_loading_view() -> Element(Msg) {
  html.div([attribute.class("loading")], [
    html.p([], [element.text("Loading stores...")]),
  ])
}

fn error_view(message: String) -> Element(Msg) {
  html.div([attribute.class("error")], [
    html.p([], [element.text("Failed to load stores: " <> message)]),
  ])
}

fn empty_view(query: String) -> Element(Msg) {
  let message = case query {
    "" -> "No stores found."
    _ -> "No stores match \"" <> query <> "\"."
  }
  html.div([attribute.class("empty")], [
    html.p([], [element.text(message)]),
  ])
}

fn store_grid(stores: List(Store)) -> Element(Msg) {
  html.div(
    [attribute.class("store-grid")],
    list.map(stores, store_card),
  )
}

fn store_card(store: Store) -> Element(Msg) {
  html.div([attribute.class("store-card")], [
    html.h3([attribute.class("store-name")], [element.text(store.name)]),
    html.p([attribute.class("store-address")], [element.text(store.address)]),
    html.p([attribute.class("store-description")], [
      element.text(store.description),
    ]),
    rating_badge(store.average_rating, store.rating_count),
  ])
}

fn rating_badge(average: Float, count: Int) -> Element(Msg) {
  html.div([attribute.class("rating")], [
    html.span([attribute.class("rating-stars")], [
      element.text(format_rating(average)),
    ]),
    html.span([attribute.class("rating-count")], [
      element.text("(" <> int.to_string(count) <> " reviews)"),
    ]),
  ])
}

fn format_rating(rating: Float) -> String {
  let whole = float.truncate(rating)
  let frac = float.truncate({ rating -. int.to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(frac)
}

fn filter_stores(stores: List(Store), query: String) -> List(Store) {
  case string.trim(query) {
    "" -> stores
    q -> {
      let lower_q = string.lowercase(q)
      list.filter(stores, fn(store) {
        string.contains(string.lowercase(store.name), lower_q)
        || string.contains(string.lowercase(store.address), lower_q)
        || string.contains(string.lowercase(store.description), lower_q)
      })
    }
  }
}
