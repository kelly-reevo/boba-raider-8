import frontend/header
import frontend/model.{type Model}
import frontend/msg.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Main application view with header
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Header with navigation and conditional auth
    header.header(model),

    // Main content area
    html.main([attribute.class("main-content")], [
      html.p([], [element.text("Welcome to BobaRaider!")]),
    ]),
  ])
}
