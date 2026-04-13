import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
// Error types handled via msg type
import lustre/effect.{type Effect}
import gleam/option.{Some, None}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Error handling
    msg.ApiError(error) -> #(
      Model(..model, error: Some(error), is_loading: False),
      effect.none()
    )
    msg.ClearError -> #(
      Model(..model, error: None, is_loading: False),
      effect.none()
    )
    msg.RetryOperation -> #(
      Model(..model, is_loading: True, error: None),
      effect.none()
    )
    msg.GoBack -> #(
      Model(..model, error: None),
      effect.none()
    )

    // Loading state
    msg.SetLoading(loading) -> #(
      Model(..model, is_loading: loading),
      effect.none()
    )

    // Validation
    msg.SetValidationErrors(errors) -> #(
      Model(..model, validation_errors: errors, error: None),
      effect.none()
    )
    msg.ClearValidationErrors -> #(
      Model(..model, validation_errors: []),
      effect.none()
    )
  }
}
