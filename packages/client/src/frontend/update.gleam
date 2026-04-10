/// Application update logic with routing and authentication

import frontend/effects
import frontend/model.{type Model}
import frontend/msg.{type Msg, Home}
import gleam/string
import lustre/effect.{type Effect}
import shared.{type AuthResponse, validate_email, validate_password}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Navigation
    msg.NavigateTo(route) -> #(model.set_route(model, route), effect.none())

    // App initialization
    msg.InitApp -> init_app(model)

    // Login form handling
    msg.LoginEmailChanged(email) -> #(model.set_login_email(model, email), effect.none())
    msg.LoginPasswordChanged(password) -> #(model.set_login_password(model, password), effect.none())
    msg.LoginSubmitted -> handle_login_submit(model)
    msg.LoginSuccess(response) -> handle_login_success(model, response)
    msg.LoginFailure(error) -> #(model.set_login_error(model, shared.error_message(error)), effect.none())

    // Register form handling
    msg.RegisterUsernameChanged(username) -> #(model.set_register_username(model, username), effect.none())
    msg.RegisterEmailChanged(email) -> #(model.set_register_email(model, email), effect.none())
    msg.RegisterPasswordChanged(password) -> #(model.set_register_password(model, password), effect.none())
    msg.RegisterConfirmPasswordChanged(password) -> #(model.set_register_confirm_password(model, password), effect.none())
    msg.RegisterSubmitted -> handle_register_submit(model)
    msg.RegisterSuccess(response) -> handle_register_success(model, response)
    msg.RegisterFailure(error) -> #(model.set_register_error(model, shared.error_message(error)), effect.none())

    // Logout handling
    msg.LogoutRequested -> handle_logout(model)
    msg.LogoutCompleted -> #(model.logout(model), effects.clear_token())

    // localStorage callbacks
    msg.TokenLoadedFromStorage(user, token) -> #(model.set_logged_in(model, user, token), effect.none())
    msg.TokenStorageError(_) -> #(model.set_logged_out(model), effect.none())
    msg.TokenCleared -> #(model, effect.none())

    // Legacy counter messages
    msg.Increment -> #(model, effect.none())
    msg.Decrement -> #(model, effect.none())
    msg.Reset -> #(model, effect.none())
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
