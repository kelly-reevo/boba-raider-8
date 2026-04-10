import frontend/model.{type Model, CreateStorePage, HomePage}
import frontend/msg.{type Msg, CreateStoreMsg, NavigateToCreateStore}
import frontend/pages/create_store_page
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    view_navigation(),
    view_page_content(model)
  ])
}

/// Navigation header
fn view_navigation() -> Element(Msg) {
  html.nav([attribute.class("main-nav")], [
    html.a([attribute.href("/"), attribute.class("logo")], [
      element.text("boba-raider-8")
    ]),
    html.div([attribute.class("nav-links")], [
      html.a([attribute.href("/"), attribute.class("nav-link")], [
        element.text("Home")
      ]),
      html.button(
        [
          attribute.class("nav-link btn-link"),
          event.on_click(NavigateToCreateStore)
        ],
        [element.text("Create Store")]
      )
    ])
  ])
}

/// Route to correct page view
fn view_page_content(model: Model) -> Element(Msg) {
  case model.current_page {
    HomePage -> view_home()
    CreateStorePage(state) -> {
      // Map page view to global Msg type
      element.map(create_store_page.view(state), fn(m) { CreateStoreMsg(m) })
    }
  }
}

/// Home page view
fn view_home() -> Element(Msg) {
  html.div([attribute.class("home-page")], [
    html.h1([], [element.text("Welcome to boba-raider-8")]),
    html.p([], [
      element.text("Click 'Create Store' to add a new store listing.")
    ])
  ])
}
