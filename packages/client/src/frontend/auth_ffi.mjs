import { Ok, Error } from "../../../build/dev/javascript/prelude.mjs";

const TOKEN_KEY = "auth_token";

export function get_saved_token() {
  try {
    return localStorage.getItem(TOKEN_KEY) || "";
  } catch {
    return "";
  }
}

export function save_token(token) {
  try {
    localStorage.setItem(TOKEN_KEY, token);
  } catch {
    // Storage unavailable
  }
}

export function clear_token() {
  try {
    localStorage.removeItem(TOKEN_KEY);
  } catch {
    // Storage unavailable
  }
}

function handle_auth_response(res, data, dispatch_ok, dispatch_err) {
  if (res.ok && data.token && data.user) {
    dispatch_ok(data.token, data.user.id, data.user.username, data.user.email);
  } else {
    dispatch_err(data.error || "Request failed");
  }
}

export function do_login(email, password, dispatch_ok, dispatch_err) {
  fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  })
    .then((res) => res.json().then((data) => handle_auth_response(res, data, dispatch_ok, dispatch_err)))
    .catch((err) => dispatch_err(err.message || "Network error"));
}

export function do_register(username, email, password, dispatch_ok, dispatch_err) {
  fetch("/api/auth/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, email, password }),
  })
    .then((res) => res.json().then((data) => handle_auth_response(res, data, dispatch_ok, dispatch_err)))
    .catch((err) => dispatch_err(err.message || "Network error"));
}

export function do_fetch_profile(token, dispatch_ok, dispatch_err) {
  fetch("/api/auth/profile", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + token,
    },
  })
    .then((res) =>
      res.json().then((data) => {
        if (res.ok && data.id) {
          dispatch_ok(data.id, data.username, data.email);
        } else {
          dispatch_err(data.error || "Failed to load profile");
        }
      })
    )
    .catch((err) => dispatch_err(err.message || "Network error"));
}
