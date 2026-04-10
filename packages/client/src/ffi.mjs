/// FFI JavaScript module for browser interactions

/**
 * Navigate to a path using the History API (client-side navigation)
 */
export function navigateTo(path) {
  window.history.pushState({}, "", path);
  // Dispatch a custom event that Gleam can listen to
  window.dispatchEvent(new CustomEvent("routechange", { detail: path }));
}

/**
 * Get the current browser path
 */
export function getCurrentPath() {
  return window.location.pathname;
}

/**
 * Setup listener for browser back/forward buttons (popstate event)
 */
export function setupPopstateListener(callback) {
  window.addEventListener("popstate", () => {
    callback(window.location.pathname);
  });

  // Also listen for custom routechange events from navigateTo
  window.addEventListener("routechange", (event) => {
    if (event.detail) {
      callback(event.detail);
    }
  });
}

/**
 * Dispatch a route change message to the Lustre app
 * This is called from Gleam to trigger navigation updates
 */
export function dispatchRouteChange(route) {
  // The Lustre app handles this via the RouteChanged message
  // This is a placeholder for any additional JS-side handling
  return null;
}

/**
 * Check authentication status from server
 */
export function checkAuthStatus(callback) {
  fetch("/api/auth/status", {
    method: "GET",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
  })
    .then((response) => response.json())
    .then((data) => {
      callback(JSON.stringify(data));
    })
    .catch((error) => {
      callback(JSON.stringify({ authenticated: false, user: null }));
    });
}

/**
 * Parse auth JSON response into Gleam tuple
 * Returns: #(Bool, String, String) - (authenticated, user_id, username)
 */
export function parseAuthJson(jsonStr) {
  try {
    const data = JSON.parse(jsonStr);
    if (data.authenticated && data.user) {
      return [true, data.user.id || "", data.user.username || ""];
    }
    return [false, "", ""];
  } catch (e) {
    return [false, "", ""];
  }
}

/**
 * Login request to server
 */
export function login(username, password, callback) {
  fetch("/api/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify({ username, password }),
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then((data) => {
      callback(JSON.stringify({ success: true, ...data }));
    })
    .catch((error) => {
      callback(JSON.stringify({ success: false, error: error.message }));
    });
}

/**
 * Parse login JSON response into Gleam tuple
 * Returns: #(Bool, String, String) - (success, user_id, username)
 */
export function parseLoginJson(jsonStr) {
  try {
    const data = JSON.parse(jsonStr);
    if (data.success) {
      return [true, data.user_id || "", data.username || ""];
    }
    return [false, "", ""];
  } catch (e) {
    return [false, "", ""];
  }
}

/**
 * Logout request to server
 */
export function logout(callback) {
  fetch("/api/auth/logout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
  })
    .then((response) => response.json())
    .then((data) => {
      callback(JSON.stringify({ success: true }));
    })
    .catch((error) => {
      callback(JSON.stringify({ success: true }));
    });
}
