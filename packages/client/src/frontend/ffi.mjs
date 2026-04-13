// FFI functions for the frontend client

/**
 * Delete a todo item by ID
 * @param {string} id - The todo ID
 * @param {function} onSuccess - Callback with status code
 * @param {function} onError - Callback with error message
 */
export function deleteTodo(id, onSuccess, onError) {
  fetch(`/api/todos/${id}`, { method: 'DELETE' })
    .then(response => {
      onSuccess(response.status);
    })
    .catch(error => {
      onError(error.message);
    });
}

/**
 * Fetch all todos from the API
 * @param {function} onSuccess - Callback with JSON string
 * @param {function} onError - Callback with error message
 */
export function fetchTodos(onSuccess, onError) {
  fetch('/api/todos')
    .then(response => {
      if (response.ok) {
        return response.text();
      }
      throw new Error(`HTTP ${response.status}`);
    })
    .then(text => {
      onSuccess(text);
    })
    .catch(error => {
      onError(error.message);
    });
}

/**
 * Parse todos JSON string into Gleam-compatible list
 * @param {string} jsonString - JSON string to parse
 * @returns {{Ok: Array} | {Error: null}} - Result with parsed todos
 */
export function parseTodos(jsonString) {
  try {
    const parsed = JSON.parse(jsonString);
    if (!Array.isArray(parsed)) {
      return { Error: null };
    }

    // Convert each JSON todo to a Gleam Todo record
    const todos = parsed.map(item => {
      return new Todo(
        item.id || '',
        item.title || '',
        item.description || '',
        item.priority || '',
        item.completed || false,
        item.created_at || 0,
        item.updated_at || 0
      );
    });

    return { Ok: todos };
  } catch (e) {
    return { Error: null };
  }
}

/**
 * Todo class for creating Gleam-compatible Todo objects
 */
class Todo {
  constructor(id, title, description, priority, completed, created_at, updated_at) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.priority = priority;
    this.completed = completed;
    this.created_at = created_at;
    this.updated_at = updated_at;
  }
}
