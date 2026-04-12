/**
 * API Client Module
 * Handles HTTP communication with the backend API.
 */

const API_BASE_URL = '/api';

/**
 * Create a new todo
 * @param {Object} todo - Todo data
 * @param {string} todo.title - Todo title
 * @param {string} [todo.description] - Todo description
 * @returns {Promise<{data?: Object, error?: Object}>} - Result with either data or error
 */
export async function createTodo(todo) {
  try {
    const response = await fetch(`${API_BASE_URL}/todos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(todo),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        error: {
          status: response.status,
          statusText: response.statusText,
          response: errorData,
        },
      };
    }

    const data = await response.json();
    return { data };
  } catch (error) {
    return { error };
  }
}

/**
 * Fetch all todos
 * @returns {Promise<{data?: Array, error?: Object}>} - Result with either data or error
 */
export async function fetchTodos() {
  try {
    const response = await fetch(`${API_BASE_URL}/todos`);

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        error: {
          status: response.status,
          statusText: response.statusText,
          response: errorData,
        },
      };
    }

    const data = await response.json();
    return { data };
  } catch (error) {
    return { error };
  }
}
