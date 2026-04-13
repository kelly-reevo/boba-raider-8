// FFI module for HTTP fetch operations
// This module provides JavaScript implementations for Gleam HTTP effects

/**
 * Parse a todo from JSON
 */
function parseTodo(data) {
  return {
    id: String(data.id || ""),
    title: String(data.title || ""),
    description: String(data.description || ""),
    completed: Boolean(data.completed || false)
  };
}

/**
 * Build a URL from a request object
 */
function buildUrl(req) {
  // req.path contains the path like "/api/todos"
  return req.path || "/";
}

/**
 * Extract headers from request
 */
function buildHeaders(req) {
  const headers = new Headers();
  if (req.headers) {
    req.headers.forEach(h => {
      headers.append(h[0], h[1]);
    });
  }
  return headers;
}

/**
 * Fetch all todos
 */
export function fetchTodos(req, dispatch) {
  const url = buildUrl(req);
  const headers = buildHeaders(req);

  fetch(url, { method: "GET", headers })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      const todos = Array.isArray(data) ? data.map(parseTodo) : [];
      dispatch({
        type: "LoadTodosSuccess",
        todos: todos
      });
    })
    .catch(error => {
      dispatch({
        type: "LoadTodosError",
        error: error.message || "Failed to load todos"
      });
    });
}

/**
 * Submit a new todo
 */
export function submitTodo(req, dispatch) {
  const url = buildUrl(req);
  const headers = buildHeaders(req);

  fetch(url, {
    method: "POST",
    headers: headers,
    body: req.body
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      const todo = parseTodo(data);
      dispatch({
        type: "SubmitTodoSuccess",
        todo: todo
      });
    })
    .catch(error => {
      dispatch({
        type: "SubmitTodoError",
        error: error.message || "Failed to submit todo"
      });
    });
}

/**
 * Toggle a todo's completed status
 */
export function toggleTodo(req, todoId, dispatch) {
  const url = buildUrl(req);
  const headers = buildHeaders(req);

  fetch(url, {
    method: "PATCH",
    headers: headers,
    body: req.body
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      const todo = parseTodo(data);
      dispatch({
        type: "ToggleTodoSuccess",
        todo: todo
      });
    })
    .catch(error => {
      dispatch({
        type: "ToggleTodoError",
        error: error.message || "Failed to update todo",
        todo_id: todoId
      });
    });
}

/**
 * Delete a todo
 */
export function deleteTodo(req, todoId, dispatch) {
  const url = buildUrl(req);
  const headers = buildHeaders(req);

  fetch(url, {
    method: "DELETE",
    headers: headers
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json().catch(() => ({})); // Handle empty response
    })
    .then(() => {
      dispatch({
        type: "DeleteTodoSuccess",
        todo_id: todoId
      });
    })
    .catch(error => {
      dispatch({
        type: "DeleteTodoError",
        error: error.message || "Failed to delete todo",
        todo_id: todoId
      });
    });
}
