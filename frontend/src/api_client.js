/**
 * API client for boba-raider-8
 * Handles all HTTP communication with the backend
 */

const API_BASE_URL = '/api';

/**
 * Update a todo's completion status
 * @param {string} id - The todo ID
 * @param {Object} data - The update data
 * @param {boolean} data.completed - The new completion status
 * @returns {Promise<Object>} - The updated todo object
 * @throws {Error} - On network or API errors (includes status property for HTTP errors)
 */
export async function updateTodo(id, data) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = new Error(`Failed to update todo: ${response.statusText}`);
    error.status = response.status;

    if (response.status === 404) {
      error.message = 'Todo not found';
    } else if (response.status >= 500) {
      error.message = 'Server error';
    }

    throw error;
  }

  return response.json();
}

/**
 * Fetch all todos
 * @returns {Promise<Array>} - Array of todo objects
 */
export async function fetchTodos() {
  const response = await fetch(`${API_BASE_URL}/todos`);

  if (!response.ok) {
    const error = new Error(`Failed to fetch todos: ${response.statusText}`);
    error.status = response.status;
    throw error;
  }

  return response.json();
}

/**
 * Create a new todo
 * @param {Object} data - The todo data
 * @param {string} data.title - The todo title
 * @returns {Promise<Object>} - The created todo object
 */
export async function createTodo(data) {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = new Error(`Failed to create todo: ${response.statusText}`);
    error.status = response.status;
    throw error;
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
    const error = new Error(`Failed to delete todo: ${response.statusText}`);
    error.status = response.status;
    throw error;
  }
}
