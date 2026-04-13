/**
 * API client for interacting with the backend.
 * Provides functions for CRUD operations on todos.
 */

const API_BASE_URL = '/api';

/**
 * Update a todo's properties (e.g., completion status).
 * @param {string} id - The todo ID
 * @param {Object} updates - Object containing fields to update (e.g., { completed: true })
 * @returns {Promise<Object>} - The updated todo object
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
    const errorText = await response.text().catch(() => 'Unknown error');
    throw new Error(`Failed to update todo: ${errorText}`);
  }

  return response.json();
}
