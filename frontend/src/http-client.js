/**
 * HTTP Client for todo API operations
 */

const API_BASE = '/api';

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
  };
}

export default {
  deleteTodo,
  createHttpClient,
};
