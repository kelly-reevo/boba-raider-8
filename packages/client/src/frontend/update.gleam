import frontend/model.{type Model, Error, Model, Toast}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Toast notifications
    msg.ShowToast(message, toast_type, duration_ms) -> {
      let toast_id = "toast-" <> int.to_string(model.next_toast_id)
      let new_toast = Toast(toast_id, message, toast_type, duration_ms)
      let new_model =
        Model(
          ..model,
          toasts: list.append(model.toasts, [new_toast]),
          next_toast_id: model.next_toast_id + 1,
        )
      #(new_model, effect.none())
    }

    msg.RemoveToast(toast_id) -> {
      let filtered_toasts =
        list.filter(model.toasts, fn(t) { t.id != toast_id })
      #(Model(..model, toasts: filtered_toasts), effect.none())
    }

    msg.ClearAllToasts -> #(Model(..model, toasts: []), effect.none())

    // Global error handling
    msg.SetGlobalError(error) -> {
      #(Model(..model, global_error: Some(error)), effect.none())
    }

    msg.ClearGlobalError -> #(Model(..model, global_error: None), effect.none())

    // API error handling - creates both toast and global error
    msg.ApiErrorOccurred(operation, details) -> {
      let error_message = operation <> " failed: " <> details
      let toast_id = "toast-" <> int.to_string(model.next_toast_id)
      let error_toast =
        Toast(toast_id, error_message, Error, 5000)
      let new_model =
        Model(
          ..model,
          global_error: Some(error_message),
          toasts: list.append(model.toasts, [error_toast]),
          next_toast_id: model.next_toast_id + 1,
        )
      #(new_model, effect.none())
    }
  }
}
