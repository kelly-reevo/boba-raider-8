import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/option.{None}
import lustre/effect.{type Effect}

import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg, Home}
import gleam/string
import lustre/effect.{type Effect}
import shared.{type AuthResponse, validate_email, validate_password}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter demo messages (legacy)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Auth messages: logout clears storage then redirects via StorageCleared
    msg.Logout -> #(Model(..model, user: None), effects.logout())
    msg.StorageCleared -> #(model, effect.none())
    msg.RedirectComplete -> #(model, effect.none())
  }
}

/// Initialize app - load auth token from localStorage
fn init_app(model: Model) -> #(Model, Effect(Msg)) {
  #(model.set_route(model, Home), effects.load_token_from_storage())
}

/// Handle login form submission with validation
fn handle_login_submit(model: Model) -> #(Model, Effect(Msg)) {
  let form = model.login_form

  // Validate fields
  case validate_login_form(form) {
    Error(error_msg) -> #(model.set_login_error(model, error_msg), effect.none())
    Ok(_) -> {
      let loading_model = model.set_login_loading(model, True)
      #(loading_model, effects.submit_login(form.email, form.password))
    }
  }
}

/// Validate login form fields
fn validate_login_form(form: model.LoginForm) -> Result(Nil, String) {
  case form.email, form.password {
    "", _ -> Error("Email is required")
    _, "" -> Error("Password is required")
    email, _ -> {
      case validate_email(email) {
        Error(_) -> Error("Please enter a valid email address")
        Ok(_) -> Ok(Nil)
      }
    }
  }
}

/// Handle successful login - store token and redirect
fn handle_login_success(
  model: Model,
  response: AuthResponse,
) -> #(Model, Effect(Msg)) {
  let updated_model = model.set_logged_in(model, response.user, response.token)
  let save_effect = effects.save_token_to_storage(response.user, response.token)
  #(updated_model, save_effect)
}

/// Handle register form submission with validation
fn handle_register_submit(model: Model) -> #(Model, Effect(Msg)) {
  let form = model.register_form

  // Validate fields
  case validate_register_form(form) {
    Error(error_msg) -> #(model.set_register_error(model, error_msg), effect.none())
    Ok(_) -> {
      let loading_model = model.set_register_loading(model, True)
      let effect = effects.submit_register(
        form.username,
        form.email,
        form.password,
      )
      #(loading_model, effect)
    }
  }
}

/// Validate registration form fields
fn validate_register_form(form: model.RegisterForm) -> Result(Nil, String) {
  // Check empty fields first
  case form.username, form.email, form.password, form.confirm_password {
    "", _, _, _ -> Error("Username is required")
    _, "", _, _ -> Error("Email is required")
    _, _, "", _ -> Error("Password is required")
    _, _, _, "" -> Error("Please confirm your password")
    username, email, password, confirm_password -> {
      // Check username length
      case string.length(username) >= 3 {
        False -> Error("Username must be at least 3 characters")
        True -> {
          // Check email format
          case validate_email(email) {
            Error(_) -> Error("Please enter a valid email address")
            Ok(_) -> {
              // Check password length
              case validate_password(password) {
                Error(_) -> Error("Password must be at least 8 characters")
                Ok(_) -> {
                  // Check passwords match
                  case password == confirm_password {
                    False -> Error("Passwords do not match")
                    True -> Ok(Nil)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Handle successful registration - store token and redirect
fn handle_register_success(
  model: Model,
  response: AuthResponse,
) -> #(Model, Effect(Msg)) {
  let updated_model = model.set_logged_in(model, response.user, response.token)
  let save_effect = effects.save_token_to_storage(response.user, response.token)
  #(updated_model, save_effect)
}

/// Handle logout request
fn handle_logout(model: Model) -> #(Model, Effect(Msg)) {
  #(model.logout(model), effects.clear_token())
}
