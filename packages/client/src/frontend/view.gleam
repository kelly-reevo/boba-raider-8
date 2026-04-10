import gleam/int
import frontend/components/error_boundary
import frontend/components/toast
import frontend/model.{type Model, Error, Info, Success, Warning}
import frontend/msg.{type Msg, ApiErrorOccurred, ShowToast}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    // Toast container - fixed position overlay for all notifications
    toast.toast_container(model.toasts),

    // Error boundary wraps main content
    error_boundary.error_boundary(model, [
      html.h1([], [element.text("boba-raider-8")]),

      // Demo controls for testing error handling
      html.div([attribute.class("demo-controls")], [
        html.h2([], [element.text("Error Handling Demo")]),
        html.div([attribute.class("demo-buttons")], [
          html.button(
            [event.on_click(ShowToast("Operation successful!", Success, 3000))],
            [element.text("Show Success")],
          ),
          html.button(
            [event.on_click(ShowToast("Something went wrong", Error, 5000))],
            [element.text("Show Error")],
          ),
          html.button(
            [event.on_click(ShowToast("Please check your input", Warning, 4000))],
            [element.text("Show Warning")],
          ),
          html.button(
            [event.on_click(ShowToast("New data available", Info, 3000))],
            [element.text("Show Info")],
          ),
          html.button(
            [
              event.on_click(ApiErrorOccurred(
                "Save",
                "Network connection failed",
              )),
            ],
            [element.text("Trigger API Error")],
          ),
        ]),
      ]),

      // Original counter
      html.div([attribute.class("counter")], [
        html.button([event.on_click(msg.Decrement)], [element.text("-")]),
        html.span([attribute.class("count")], [
          element.text("Count: " <> int.to_string(model.count)),
        ]),
        html.button([event.on_click(msg.Increment)], [element.text("+")]),
      ]),
      html.button([event.on_click(msg.Reset), attribute.class("reset")], [
        element.text("Reset"),
      ]),
    ]),
  ])
}
