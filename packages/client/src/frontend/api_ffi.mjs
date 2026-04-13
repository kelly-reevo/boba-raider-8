// FFI module for making HTTP requests via native fetch

/**
 * Patch a todo's completed status with callbacks for Gleam
 * @param {string} id - Todo ID
 * @param {boolean} completed - New completed status
 * @param {Function} onSuccess - Callback for successful response
 * @param {Function} onError - Callback for error
 */
export function patchTodo(id, completed, onSuccess, onError) {
  fetch(`/api/todos/${id}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed: completed })
  }).then(response => {
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return response.json();
  }).then(data => {
    onSuccess(data);
  }).catch(error => {
    onError(error.message || 'Network error');
  });
}

/**
 * Fetch all todos with callbacks
 * @param {Function} onSuccess - Callback for successful response
 * @param {Function} onError - Callback for error
 */
export function fetchTodos(onSuccess, onError) {
  fetch('/api/todos')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then(data => onSuccess(data))
    .catch(error => onError(error.message || 'Network error'));
}
