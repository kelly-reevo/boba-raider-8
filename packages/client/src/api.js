/**
 * HTTP Client API for Todo operations
 * Provides fetchTodos, createTodo, updateTodo, deleteTodo functions
 */

const API_BASE_URL = '/api';

/**
 * Handle API response and parse JSON or errors
 * @param {Response} response - Fetch response object
 * @returns {Promise<any>} - Parsed JSON on success, rejected promise on error
 */
async function handleResponse(response) {
  if (response.ok) {
    // For 204 No Content (delete), return undefined
    if (response.status === 204) {
      return undefined;
    }
    return response.json();
  }

  // Error response - try to parse error details
  let errorData;
  try {
    errorData = await response.json();
  } catch (e) {
    // If JSON parsing fails, create generic error based on status
    errorData = {
      errors: [{
        field: 'general',
        message: `HTTP ${response.status}: ${response.statusText}`
      }]
    };
  }

  // Ensure error has the expected structure
  if (!errorData.errors || !Array.isArray(errorData.errors)) {
    errorData = {
      errors: [{
        field: 'general',
        message: errorData.message || `Request failed with status ${response.status}`
      }]
    };
  }

  throw errorData;
}

/**
 * Fetch all todos
 * @returns {Promise<Array>} - Array of todo objects
 */
export async function fetchTodos() {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json'
    }
  });
  return await handleResponse(response);
}

/**
 * Create a new todo
 * @param {Object} data - Todo data with title, description, priority
 * @returns {Promise<Object>} - Created todo with id
 */
export async function createTodo(data) {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify(data)
  });
  return await handleResponse(response);
}

/**
 * Update an existing todo
 * @param {string} id - Todo ID
 * @param {Object} data - Partial todo data to update
 * @returns {Promise<Object>} - Updated todo object
 */
export async function updateTodo(id, data) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify(data)
  });
  return await handleResponse(response);
}

/**
 * Delete a todo
 * @param {string} id - Todo ID
 * @returns {Promise<void>} - Resolves on success
 */
export async function deleteTodo(id) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'DELETE',
    headers: {
      'Accept': 'application/json'
    }
  });
  return await handleResponse(response);
}
