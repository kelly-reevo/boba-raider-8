import frontend/model.{type Model, Error, Model, Toast}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

/// Main update function
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

/// Handle route changes with authentication guard
fn handle_route_change(model: Model, route_val: Route) -> #(Model, Effect(Msg)) {
  // Check if route requires auth and user is not authenticated
  case is_protected(route_val) && !is_authenticated(model) {
    True -> {
      // Save current path and redirect to login
      let current_path = to_path(route_val)
      let new_model = Model(
        ..model,
        current_route: Login,
        post_login_redirect: Some(current_path),
      )
      #(new_model, effects.navigate_to(login_redirect_path()))
    }
    False -> {
      // Allow access
      #(Model(..model, current_route: route_val), effect.none())
    }
  }
}

/// Handle programmatic navigation with auth check
fn handle_navigate_to(model: Model, route_val: Route) -> #(Model, Effect(Msg)) {
  case can_access_route(model, route_val) {
    True -> {
      let path = to_path(route_val)
      #(Model(..model, current_route: route_val), effects.navigate_to(path))
    }
    False -> {
      // Save intended destination and redirect to login
      let path = to_path(route_val)
      let new_model = Model(
        ..model,
        post_login_redirect: Some(path),
      )
      #(new_model, effects.navigate_to(login_redirect_path()))
    }
  }
}

/// Validate form data
fn validate_form(form_data: DrinkFormData) -> Result(Nil, String) {
  case form_data.name {
    "" -> Error("Name is required")
    _ -> Ok(Nil)
  }
}

/// Convert form data to API input
fn form_to_input(
  form_data: DrinkFormData,
  image_url: String,
) -> CreateDrinkInput {
  let price = case float.parse(form_data.price) {
    Ok(p) -> p
    Error(_) -> 0.0
  }

  CreateDrinkInput(
    name: form_data.name,
    tea_type: form_data.tea_type,
    price: price,
    description: form_data.description,
    image_url: image_url,
    is_signature: form_data.is_signature,
  )
}
