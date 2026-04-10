// FFI for client-side browser effects

/// Logout: clear localStorage and redirect to home
export function logout() {
  localStorage.clear();
  window.location.href = "/";
}
