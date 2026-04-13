// JavaScript FFI for browser fetch API
// Provides HTTP client functionality for the Lustre frontend

/**
 * Perform an HTTP fetch and return [status, body] or null on error
 * @param {string} method - HTTP method
 * @param {string} url - Request URL
 * @param {Object|null} body - Request body for POST/PUT
 * @param {Object} headers - Request headers
 * @returns {Promise<[number, string] | null>}
 */
export async function fetchWithStatus(method, url, body, headers) {
  try {
    const options = {
      method: method,
      headers: headers,
    };

    if (body !== null && (method === "POST" || method === "PUT" || method === "PATCH")) {
      options.body = typeof body === "string" ? body : JSON.stringify(body);
    }

    const response = await fetch(url, options);
    const responseBody = await response.text();
    return [response.status, responseBody];
  } catch (error) {
    // Network error or other fetch failure
    return null;
  }
}

/**
 * Fetch todos from the API
 * @returns {Promise<{type: string, data?: any, error?: string}>}
 */
export async function fetchTodos() {
  try {
    const response = await fetch("/api/todos", {
      method: "GET",
      headers: { "Accept": "application/json" },
    });

    const body = await response.text();

    if (response.ok) {
      try {
        const data = JSON.parse(body);
        return { type: "success", data: data };
      } catch (e) {
        return { type: "error", error: "Failed to parse response" };
      }
    } else {
      try {
        const errorData = JSON.parse(body);
        return { type: "error", error: errorData.error || `HTTP ${response.status}` };
      } catch (e) {
        return { type: "error", error: `HTTP ${response.status}` };
      }
    }
  } catch (error) {
    return { type: "network_error", error: "Connection failed. Please try again." };
  }
}

/**
 * Submit a new todo
 * @param {Object} todo - Todo data
 * @returns {Promise<{type: string, data?: any, error?: string, errors?: Array}>}
 */
export async function submitTodo(todo) {
  try {
    const response = await fetch("/api/todos", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify(todo),
    });

    const body = await response.text();

    if (response.ok) {
      try {
        const data = JSON.parse(body);
        return { type: "success", data: data };
      } catch (e) {
        return { type: "error", error: "Failed to parse response" };
      }
    } else if (response.status === 422) {
      // Validation error
      try {
        const errorData = JSON.parse(body);
        return { type: "validation_error", errors: errorData.errors || [] };
      } catch (e) {
        return { type: "error", error: "Validation failed" };
      }
    } else if (response.status === 404) {
      return { type: "not_found", error: "Todo not found" };
    } else {
      try {
        const errorData = JSON.parse(body);
        return { type: "error", error: errorData.error || `HTTP ${response.status}` };
      } catch (e) {
        return { type: "error", error: `HTTP ${response.status}` };
      }
    }
  } catch (error) {
    return { type: "network_error", error: "Connection failed. Please try again." };
  }
}

/**
 * Delete a todo
 * @param {string} id - Todo ID
 * @returns {Promise<{type: string, error?: string}>}
 */
export async function deleteTodo(id) {
  try {
    const response = await fetch(`/api/todos/${id}`, {
      method: "DELETE",
      headers: { "Accept": "application/json" },
    });

    const body = await response.text();

    if (response.ok || response.status === 204) {
      return { type: "success" };
    } else if (response.status === 404) {
      try {
        const errorData = JSON.parse(body);
        return { type: "not_found", error: errorData.error || "Todo not found" };
      } catch (e) {
        return { type: "not_found", error: "Todo not found" };
      }
    } else {
      try {
        const errorData = JSON.parse(body);
        return { type: "error", error: errorData.error || `HTTP ${response.status}` };
      } catch (e) {
        return { type: "error", error: `HTTP ${response.status}` };
      }
    }
  } catch (error) {
    return { type: "network_error", error: "Connection failed. Please try again." };
  }
}

/**
 * Boundary contract: Show error in specified container
 * @param {string} container - Container identifier ('form', 'list', 'global')
 * @param {{message: string, field?: string}} error - Error object
 */
export function showError(container, error) {
  // Map container to test ID
  const containerId = `error-container-${container}`;
  const el = document.querySelector(`[data-testid="${containerId}"]`);

  if (!el) {
    console.warn(`Error container not found: ${containerId}`);
    return;
  }

  // Create error message element
  const msg = document.createElement("div");
  msg.setAttribute("data-testid", `error-message-${container}`);
  msg.textContent = error.message;

  if (error.field) {
    msg.setAttribute("data-field", error.field);
  }

  if (container === "global") {
    msg.setAttribute("role", "alert");
  }

  el.appendChild(msg);

  // Make container visible
  el.style.display = "block";
}

/**
 * Boundary contract: Clear all error displays
 */
export function clearErrors() {
  // Clear error message elements
  document.querySelectorAll('[data-testid^="error-message-"]').forEach(el => el.remove());

  // Clear field errors
  document.querySelectorAll('[data-testid^="error-field-"]').forEach(el => {
    el.textContent = "";
    el.style.display = "none";
  });

  // Clear error containers
  document.querySelectorAll('[data-testid^="error-container-"]').forEach(el => {
    el.innerHTML = "";
    el.style.display = "none";
  });

  // Clear global notification
  const globalNotification = document.querySelector('[data-testid="global-notification"]');
  if (globalNotification) {
    globalNotification.textContent = "";
    globalNotification.style.display = "none";
  }

  // Clear list error container
  const listErrorContainer = document.querySelector('[data-testid="list-error-container"]');
  if (listErrorContainer) {
    listErrorContainer.innerHTML = "";
    listErrorContainer.style.display = "none";
  }
}
