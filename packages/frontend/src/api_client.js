/**
 * API Client for Todo operations
 * Handles HTTP communication with the backend
 */

const API_BASE_URL = '/api';

/**
 * Delete a todo by ID
 * @param {string} id - The todo ID to delete
 * @returns {Promise<void>}
 * @throws {Error} When the API returns an error status
 */
export async function deleteTodo(id) {
  if (!id) {
    throw new Error('Todo ID is required');
  }

  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    if (response.status === 404) {
      const error = new Error('Todo not found');
      error.status = 404;
      throw error;
    }
    if (response.status >= 500) {
      const error = new Error('Server error');
      error.status = response.status;
      throw error;
    }
    const error = new Error(`Failed to delete todo: ${response.statusText}`);
    error.status = response.status;
    throw error;
  }
}

/**
 * Fetch all todos from the API
 * @returns {Promise<Array>} Array of todo objects
 * @throws {Error} When the API returns an error status
 */
export async function getAllTodos() {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'GET',
  });

  if (!response.ok) {
    const error = new Error(`Failed to fetch todos: ${response.statusText}`);
    error.status = response.status;
    throw error;
  }

  return response.json();
}
