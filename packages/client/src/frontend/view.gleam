/// View functions for all routes with loading/empty/error/populated states

import frontend/model.{
  type Model, type PageData, AuthAuthenticated, AuthLoading,
  AuthUnauthenticated, PageEmpty, PageError, PageLoading, PagePopulated,
  is_authenticated, Some, None,
}
import frontend/msg.{type Msg, LoginRequested, NavigateTo, LogoutRequested}
import frontend/route.{
  Home, Login, Profile, Register, StoreCreate, StoreDetail,
  StoreEdit, StoreList, DrinkDetail, DrinkEdit, NotFound,
}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event

/// Main view function - routes to appropriate page view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    view_navbar(model),
    html.main([attribute.class("main-content")], [
      view_current_route(model),
    ]),
  ])
}

/// Navigation bar with auth state
fn view_navbar(model: Model) -> Element(Msg) {
  html.nav([attribute.class("navbar")], [
    html.div([attribute.class("nav-brand")], [
      html.a([attribute.href("/"), event.on_click(NavigateTo(Home))], [
        text("BobaRaider"),
      ]),
    ]),
    html.div([attribute.class("nav-links")], [
      html.a([attribute.href("/"), event.on_click(NavigateTo(Home))], [text("Home")]),
      html.a([attribute.href("/stores"), event.on_click(NavigateTo(StoreList))], [text("Stores")]),
    ]),
    html.div([attribute.class("nav-auth")], [
      view_auth_section(model),
    ]),
  ])
}

/// View auth section based on authentication state
fn view_auth_section(model: Model) -> Element(Msg) {
  case model.auth_state {
    AuthLoading -> html.span([attribute.class("auth-loading")], [text("Loading...")])
    AuthUnauthenticated -> html.div([], [
      html.a(
        [attribute.href("/login"), attribute.class("btn-login"), event.on_click(NavigateTo(Login))],
        [text("Login")],
      ),
      html.a(
        [attribute.href("/register"), attribute.class("btn-register"), event.on_click(NavigateTo(Register))],
        [text("Register")],
      ),
    ])
    AuthAuthenticated(_, username) -> html.div([], [
      html.a(
        [attribute.href("/profile"), attribute.class("btn-profile"), event.on_click(NavigateTo(Profile))],
        [text(username)],
      ),
      html.button([attribute.class("btn-logout"), event.on_click(LogoutRequested)], [text("Logout")]),
    ])
  }
}

/// View current route
fn view_current_route(model: Model) -> Element(Msg) {
  case model.current_route {
    Home -> view_home(model)
    StoreList -> view_store_list(model)
    StoreDetail(id) -> view_store_detail(model, id)
    StoreCreate -> view_store_create(model)
    StoreEdit(id) -> view_store_edit(model, id)
    DrinkDetail(id) -> view_drink_detail(model, id)
    DrinkEdit(id) -> view_drink_edit(model, id)
    Profile -> view_profile(model)
    Login -> view_login(model)
    Register -> view_register(model)
    NotFound(path) -> view_not_found(path)
  }
}

// ============================================
// HOME PAGE (Public)
// ============================================

fn view_home(model: Model) -> Element(Msg) {
  html.div([attribute.class("page-home")], [
    html.h1([], [text("Welcome to BobaRaider")]),
    html.p([], [text("Discover and share the best boba tea spots!")]),
    html.div([attribute.class("home-actions")], [
      html.a(
        [attribute.href("/stores"), attribute.class("btn-primary"), event.on_click(NavigateTo(StoreList))],
        [text("Explore Stores")],
      ),
      case is_authenticated(model) {
        True -> html.a(
          [attribute.href("/stores/create"), attribute.class("btn-secondary"), event.on_click(NavigateTo(StoreCreate))],
          [text("Add Store")],
        )
        False -> element.none()
      },
    ]),
  ])
}

// ============================================
// STORE LIST PAGE (Public)
// ============================================

fn view_store_list(_model: Model) -> Element(Msg) {
  // For now, show empty state - this would be populated with actual data
  html.div([attribute.class("page-store-list")], [
    html.h1([], [text("Stores")]),
    view_page_data_state(PageEmpty, fn(_) { element.none() }, "stores"),
  ])
}

// ============================================
// STORE DETAIL PAGE (Public)
// ============================================

fn view_store_detail(_model: Model, id: String) -> Element(Msg) {
  html.div([attribute.class("page-store-detail")], [
    html.h1([], [text("Store Details")]),
    html.p([], [text("Store ID: " <> id)]),
    view_page_data_state(PageEmpty, fn(_) { element.none() }, "store details"),
  ])
}

// ============================================
// STORE CREATE PAGE (Protected)
// ============================================

fn view_store_create(_model: Model) -> Element(Msg) {
  html.div([attribute.class("page-store-create")], [
    html.h1([], [text("Create New Store")]),
    html.form([attribute.class("store-form")], [
      html.div([attribute.class("form-group")], [
        html.label([], [text("Store Name")]),
        html.input([attribute.type_("text"), attribute.name("name")]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [text("Address")]),
        html.input([attribute.type_("text"), attribute.name("address")]),
      ]),
      html.button([attribute.type_("submit"), attribute.class("btn-primary")], [text("Create Store")]),
    ]),
  ])
}

// ============================================
// STORE EDIT PAGE (Protected)
// ============================================

fn view_store_edit(_model: Model, id: String) -> Element(Msg) {
  html.div([attribute.class("page-store-edit")], [
    html.h1([], [text("Edit Store")]),
    html.p([], [text("Editing store ID: " <> id)]),
    view_page_data_state(PageEmpty, fn(_) { element.none() }, "store data"),
  ])
}

// ============================================
// DRINK DETAIL PAGE (Public)
// ============================================

fn view_drink_detail(_model: Model, id: String) -> Element(Msg) {
  html.div([attribute.class("page-drink-detail")], [
    html.h1([], [text("Drink Details")]),
    html.p([], [text("Drink ID: " <> id)]),
    view_page_data_state(PageEmpty, fn(_) { element.none() }, "drink details"),
  ])
}

// ============================================
// DRINK EDIT PAGE (Protected)
// ============================================

fn view_drink_edit(_model: Model, id: String) -> Element(Msg) {
  html.div([attribute.class("page-drink-edit")], [
    html.h1([], [text("Edit Drink")]),
    html.p([], [text("Editing drink ID: " <> id)]),
    view_page_data_state(PageEmpty, fn(_) { element.none() }, "drink data"),
  ])
}

// ============================================
// PROFILE PAGE (Protected)
// ============================================

fn view_profile(model: Model) -> Element(Msg) {
  html.div([attribute.class("page-profile")], [
    html.h1([], [text("Your Profile")]),
    case model.auth_state {
      AuthAuthenticated(user_id, username) -> html.div([], [
        html.div([attribute.class("profile-card")], [
          html.h2([], [text(username)]),
          html.p([], [text("User ID: " <> user_id)]),
        ]),
      ])
      _ -> view_page_data_state(PageLoading, fn(_) { element.none() }, "profile")
    },
  ])
}

// ============================================
// LOGIN PAGE (Public)
// ============================================

fn view_login(model: Model) -> Element(Msg) {
  html.div([attribute.class("page-login")], [
    html.h1([], [text("Login")]),
    case model.post_login_redirect {
      Some(path) -> html.p([attribute.class("redirect-notice")], [
        text("Please login to access " <> path),
      ])
      None -> element.none()
    },
    html.form(
      [
        attribute.class("login-form"),
        event.on_submit(fn(_fields) { LoginRequested("", "") }),
      ],
      [
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("username")], [text("Username")]),
          html.input([
            attribute.type_("text"),
            attribute.id("username"),
            attribute.name("username"),
            attribute.required(True),
          ]),
        ]),
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("password")], [text("Password")]),
          html.input([
            attribute.type_("password"),
            attribute.id("password"),
            attribute.name("password"),
            attribute.required(True),
          ]),
        ]),
        html.button([attribute.type_("submit"), attribute.class("btn-primary")], [text("Login")]),
      ],
    ),
    html.p([attribute.class("register-link")], [
      text("Don't have an account? "),
      html.a(
        [attribute.href("/register"), event.on_click(NavigateTo(Register))],
        [text("Register")],
      ),
    ]),
  ])
}

// ============================================
// REGISTER PAGE (Public)
// ============================================

fn view_register(_model: Model) -> Element(Msg) {
  html.div([attribute.class("page-register")], [
    html.h1([], [text("Register")]),
    html.form(
      [
        attribute.class("register-form"),
        event.on_submit(fn(_fields) { NavigateTo(Login) }),
      ],
      [
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("username")], [text("Username")]),
          html.input([
            attribute.type_("text"),
            attribute.id("username"),
            attribute.name("username"),
            attribute.required(True),
          ]),
        ]),
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("email")], [text("Email")]),
          html.input([
            attribute.type_("email"),
            attribute.id("email"),
            attribute.name("email"),
            attribute.required(True),
          ]),
        ]),
        html.div([attribute.class("form-group")], [
          html.label([attribute.for("password")], [text("Password")]),
          html.input([
            attribute.type_("password"),
            attribute.id("password"),
            attribute.name("password"),
            attribute.required(True),
          ]),
        ]),
        html.button([attribute.type_("submit"), attribute.class("btn-primary")], [text("Register")]),
      ],
    ),
    html.p([attribute.class("login-link")], [
      text("Already have an account? "),
      html.a(
        [attribute.href("/login"), event.on_click(NavigateTo(Login))],
        [text("Login")],
      ),
    ]),
  ])
}

// ============================================
// NOT FOUND PAGE
// ============================================

fn view_not_found(path: String) -> Element(Msg) {
  html.div([attribute.class("page-not-found")], [
    html.h1([], [text("404 - Page Not Found")]),
    html.p([], [text("The page '" <> path <> "' could not be found.")]),
    html.a(
      [attribute.href("/"), attribute.class("btn-primary"), event.on_click(NavigateTo(Home))],
      [text("Go Home")],
    ),
  ])
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/// Render page data state with all states (loading, empty, error, populated)
fn view_page_data_state(
  page_data: PageData(a),
  view_populated: fn(a) -> Element(Msg),
  resource_name: String,
) -> Element(Msg) {
  case page_data {
    PageLoading -> html.div([attribute.class("state-loading")], [
      html.p([], [text("Loading " <> resource_name <> "...")]),
    ])
    PageEmpty -> html.div([attribute.class("state-empty")], [
      html.p([], [text("No " <> resource_name <> " available.")]),
    ])
    PageError(message) -> html.div([attribute.class("state-error")], [
      html.p([], [text("Error: " <> message)]),
    ])
    PagePopulated(data) -> view_populated(data)
  }
}
