/// Application state with routing and authentication support

import shared.{type User, type AuthToken, User, AuthToken}
import frontend/msg as msg

/// Re-export Route type
pub type Route =
  msg.Route

/// Login form state
pub type LoginForm {
  LoginForm(
    email: String,
    password: String,
    is_loading: Bool,
    error: String,
  )
}

/// Registration form state
pub type RegisterForm {
  RegisterForm(
    username: String,
    email: String,
    password: String,
    confirm_password: String,
    is_loading: Bool,
    error: String,
  )
}

/// Authentication state
pub type AuthState {
  LoggedOut
  LoggedIn(user: User, token: AuthToken)
  AuthLoading
}

/// Complete application model
pub type Model {
  Model(
    route: Route,
    auth: AuthState,
    login_form: LoginForm,
    register_form: RegisterForm,
    init_error: String,
  )
}

/// Default login form
fn default_login_form() -> LoginForm {
  LoginForm(
    email: "",
    password: "",
    is_loading: False,
    error: "",
  )
}

/// Default registration form
fn default_register_form() -> RegisterForm {
  RegisterForm(
    username: "",
    email: "",
    password: "",
    confirm_password: "",
    is_loading: False,
    error: "",
  )
}

/// Default model state
pub fn default() -> Model {
  Model(
    route: msg.Home,
    auth: AuthLoading,
    login_form: default_login_form(),
    register_form: default_register_form(),
    init_error: "",
  )
}

/// Set the current route
pub fn set_route(model: Model, route: Route) -> Model {
  Model(..model, route: route)
}

/// Update login form email
pub fn set_login_email(model: Model, email: String) -> Model {
  let form = model.login_form
  Model(..model, login_form: LoginForm(..form, email: email, error: ""))
}

/// Update login form password
pub fn set_login_password(model: Model, password: String) -> Model {
  let form = model.login_form
  Model(..model, login_form: LoginForm(..form, password: password, error: ""))
}

/// Set login form loading state
pub fn set_login_loading(model: Model, is_loading: Bool) -> Model {
  let form = model.login_form
  Model(..model, login_form: LoginForm(..form, is_loading: is_loading))
}

/// Set login form error
pub fn set_login_error(model: Model, error: String) -> Model {
  let form = model.login_form
  Model(..model, login_form: LoginForm(..form, error: error, is_loading: False))
}

/// Clear login form
pub fn clear_login_form(model: Model) -> Model {
  Model(..model, login_form: default_login_form())
}

/// Update register form username
pub fn set_register_username(model: Model, username: String) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, username: username, error: ""))
}

/// Update register form email
pub fn set_register_email(model: Model, email: String) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, email: email, error: ""))
}

/// Update register form password
pub fn set_register_password(model: Model, password: String) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, password: password, error: ""))
}

/// Update register form confirm password
pub fn set_register_confirm_password(model: Model, password: String) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, confirm_password: password, error: ""))
}

/// Set register form loading state
pub fn set_register_loading(model: Model, is_loading: Bool) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, is_loading: is_loading))
}

/// Set register form error
pub fn set_register_error(model: Model, error: String) -> Model {
  let form = model.register_form
  Model(..model, register_form: RegisterForm(..form, error: error, is_loading: False))
}

/// Clear register form
pub fn clear_register_form(model: Model) -> Model {
  Model(..model, register_form: default_register_form())
}

/// Set authentication state to logged in
pub fn set_logged_in(model: Model, user: User, token: AuthToken) -> Model {
  Model(..model, auth: LoggedIn(user, token), route: msg.Home)
}

/// Set authentication state to logged out
pub fn set_logged_out(model: Model) -> Model {
  Model(..model, auth: LoggedOut)
}

/// Complete logout - clear auth and forms
pub fn logout(model: Model) -> Model {
  Model(..model, auth: LoggedOut, route: msg.Home)
}

/// Set init error (e.g., from localStorage parse failure)
pub fn set_init_error(model: Model, error: String) -> Model {
  Model(..model, init_error: error, auth: LoggedOut)
}

/// Check if user is authenticated
pub fn is_authenticated(model: Model) -> Bool {
  case model.auth {
    LoggedIn(_, _) -> True
    _ -> False
  }
}

/// Get current user if logged in
pub fn current_user(model: Model) -> User {
  case model.auth {
    LoggedIn(user, _) -> user
    _ -> User("", "", "")
  }
}

/// Get auth token if logged in
pub fn auth_token(model: Model) -> AuthToken {
  case model.auth {
    LoggedIn(_, token) -> token
    _ -> AuthToken("", "")
  }
}
