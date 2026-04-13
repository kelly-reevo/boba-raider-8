/**
 * API client for todo operations
 * Handles all HTTP communication with the backend
 */

const API_BASE_URL = '/api';

/**
 * Update a todo's completion status
 * @param {string} id - The todo ID
 * @param {Object} updates - The updates to apply
 * @param {boolean} updates.completed - The new completion status
 * @returns {Promise<Object>} - The updated todo
 * @throws {Error} - If the request fails
 */
export async function updateTodo(id, updates) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
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
 * Fetch all todos
 * @returns {Promise<Array>} - Array of todos
 */
export async function fetchTodos() {
  const response = await fetch(`${API_BASE_URL}/todos`);

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error || `Failed to fetch todos: ${response.status}`);
  }

  return response.json();
}

/**
 * Create a new todo
 * @param {Object} todo - The todo to create
 * @param {string} todo.title - The todo title
 * @returns {Promise<Object>} - The created todo
 */
export async function createTodo(todo) {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todo),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error || `Failed to create todo: ${response.status}`);
  }

  return response.json();
}

/**
 * Delete a todo
 * @param {string} id - The todo ID
 * @returns {Promise<void>}
 */
export async function deleteTodo(id) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error || `Failed to delete todo: ${response.status}`);
  }
}
