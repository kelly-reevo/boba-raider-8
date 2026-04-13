/**
 * HTTP client for todo API operations
 * Consolidated module with all API methods
 */

const API_BASE = '/api';

/**
 * Fetch all todos
 * @returns {Promise<Response>} Fetch response
 */
export async function fetchTodos() {
  const response = await fetch(`${API_BASE}/todos`);
  return response;
}

/**
 * Create a new todo
 * @param {Object} todo - The todo to create
 * @param {string} todo.title - The todo title
 * @param {string} todo.description - The todo description
 * @returns {Promise<Response>} Fetch response
 */
export async function createTodo(todo) {
  const response = await fetch(`${API_BASE}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todo),
  });

  return response;
}

/**
 * Update a todo's completion status
 * @param {string} id - The todo ID
 * @param {Object} updates - The updates to apply
 * @param {boolean} updates.completed - The new completion status
 * @returns {Promise<Object>} - The updated todo
 * @throws {Error} - If the request fails
 */
export async function updateTodo(id, updates) {
  const response = await fetch(`${API_BASE}/todos/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(updates),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error || `Failed to update todo: ${response.status}`);
  }

  return response.json();
}

/**
 * Delete a todo by ID
 * @param {string} id - The todo ID to delete
 * @returns {Promise<{status: number}>}
 * @throws {Error} With status property for HTTP error codes
 */
export async function deleteTodo(id) {
  const response = await fetch(`${API_BASE}/todos/${id}`, {
    method: 'DELETE',
    headers: {
      'Accept': 'application/json',
    },
  });

  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}: ${response.statusText}`);
    error.status = response.status;
    throw error;
  }

  return { status: response.status };
}

/**
 * Create HTTP client instance (for compatibility with tests that expect object interface)
 */
export function createHttpClient() {
  return {
    deleteTodo,
    createTodo,
    updateTodo,
    fetchTodos,
  };
}

export default {
  deleteTodo,
  createTodo,
  updateTodo,
  fetchTodos,
  createHttpClient,
};
