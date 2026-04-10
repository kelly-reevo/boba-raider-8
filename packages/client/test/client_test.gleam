import gleeunit
import gleeunit/should
import frontend/model
import frontend/msg

pub fn main() {
  gleeunit.main()
}

/// Test that default model initializes correctly
pub fn default_model_test() {
  let m = model.default()

  // Should start on Home route
  should.equal(m.route, msg.Home)

  // Should start in AuthLoading state
  should.equal(m.auth, model.AuthLoading)

  // Login form should be empty
  should.equal(m.login_form.email, "")
  should.equal(m.login_form.password, "")
  should.equal(m.login_form.is_loading, False)
  should.equal(m.login_form.error, "")

  // Register form should be empty
  should.equal(m.register_form.username, "")
  should.equal(m.register_form.email, "")
  should.equal(m.register_form.password, "")
  should.equal(m.register_form.confirm_password, "")
  should.equal(m.register_form.is_loading, False)
  should.equal(m.register_form.error, "")
}

/// Test route setting
pub fn set_route_test() {
  let m = model.default()
  let m_with_login = model.set_route(m, msg.Login)

  should.equal(m_with_login.route, msg.Login)
}

/// Test login form updates
pub fn login_form_updates_test() {
  let m = model.default()

  let m_with_email = model.set_login_email(m, "test@example.com")
  should.equal(m_with_email.login_form.email, "test@example.com")

  let m_with_password = model.set_login_password(m, "password123")
  should.equal(m_with_password.login_form.password, "password123")

  let m_loading = model.set_login_loading(m, True)
  should.equal(m_loading.login_form.is_loading, True)

  let m_with_error = model.set_login_error(m, "Invalid credentials")
  should.equal(m_with_error.login_form.error, "Invalid credentials")
  should.equal(m_with_error.login_form.is_loading, False)
}

/// Test register form updates
pub fn register_form_updates_test() {
  let m = model.default()

  let m_with_username = model.set_register_username(m, "testuser")
  should.equal(m_with_username.register_form.username, "testuser")

  let m_with_email = model.set_register_email(m, "test@example.com")
  should.equal(m_with_email.register_form.email, "test@example.com")

  let m_with_password = model.set_register_password(m, "password123")
  should.equal(m_with_password.register_form.password, "password123")

  let m_with_confirm = model.set_register_confirm_password(m, "password123")
  should.equal(m_with_confirm.register_form.confirm_password, "password123")

  let m_loading = model.set_register_loading(m, True)
  should.equal(m_loading.register_form.is_loading, True)

  let m_with_error = model.set_register_error(m, "Username taken")
  should.equal(m_with_error.register_form.error, "Username taken")
  should.equal(m_with_error.register_form.is_loading, False)
}

/// Test authentication state transitions
pub fn auth_state_test() {
  let m = model.default()

  // Create test user and token
  let user = model.current_user(m)
  let token = model.auth_token(m)

  // Test logged out state
  let m_logged_out = model.set_logged_out(m)
  should.equal(m_logged_out.auth, model.LoggedOut)

  // Test logout (redirects to home)
  let m_after_logout = model.logout(m)
  should.equal(m_after_logout.auth, model.LoggedOut)
  should.equal(m_after_logout.route, msg.Home)
}

/// Test is_authenticated check
pub fn is_authenticated_test() {
  let m = model.default()

  // Initially not authenticated (loading state)
  should.equal(model.is_authenticated(m), False)

  // After logout, not authenticated
  let m_logged_out = model.set_logged_out(m)
  should.equal(model.is_authenticated(m_logged_out), False)
}
