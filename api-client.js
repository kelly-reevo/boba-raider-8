/**
 * API Client for todo operations
 * Provides functions to interact with the backend API
 */

const API_BASE_URL = '/api';

/**
 * Creates a new todo via the API
 * @param {Object} formData - The todo data
 * @param {string} formData.title - The todo title
 * @param {string|null} formData.description - The todo description (optional)
 * @returns {Promise<Object>} The created todo or error response
 */
export async function createTodo(formData) {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(formData),
  });

  const data = await response.json();

  if (!response.ok) {
    // Format error to match expected structure
    const error = new Error(data.message || 'Request failed');
    error.status = response.status;
    error.errors = data.errors || {};
    throw error;
  }

  return data;
}
