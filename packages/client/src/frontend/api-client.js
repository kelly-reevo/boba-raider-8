// API Client Module - Vanilla JavaScript REST API client for Todo operations

const API_BASE = '/api';

/**
 * Handles HTTP response and error processing
 * @param {Response} response - Fetch Response object
 * @returns {Promise<any>} - Parsed JSON or undefined
 * @throws {Object} - Error with status and message
 */
async function handleResponse(response) {
  if (response.ok) {
    // For 204 No Content, return undefined
    if (response.status === 204) {
      return undefined;
    }
    return await response.json();
  }

  // Handle error responses
  const error = {
    status: response.status,
    message: response.statusText || 'HTTP Error'
  };

  // Try to parse error body for additional details
  try {
    const errorBody = await response.json();
    if (errorBody.errors) {
      error.errors = errorBody.errors;
    }
  } catch {
    // Ignore JSON parse errors
  }

  throw error;
}

/**
 * Creates a new todo
 * @param {Object} data - Todo data (title, description?, priority?)
 * @returns {Promise<Object>} - Created todo object
 */
async function createTodo(data) {
  const response = await fetch(`${API_BASE}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });

  return handleResponse(response);
}

/**
 * Gets all todos with optional filter
 * @param {string} [filter] - Optional filter: 'all', 'active', 'completed'
 * @returns {Promise<Array>} - Array of todo objects
 */
async function getAllTodos(filter) {
  const url = filter
    ? `${API_BASE}/todos?filter=${encodeURIComponent(filter)}`
    : `${API_BASE}/todos`;

  const response = await fetch(url);
  return handleResponse(response);
}

/**
 * Gets a single todo by ID
 * @param {string} id - Todo ID
 * @returns {Promise<Object>} - Todo object
 */
async function getTodo(id) {
  const response = await fetch(`${API_BASE}/todos/${encodeURIComponent(id)}`);
  return handleResponse(response);
}

/**
 * Updates a todo with partial data
 * @param {string} id - Todo ID
 * @param {Object} data - Partial todo data to update
 * @returns {Promise<Object>} - Updated todo object
 */
async function updateTodo(id, data) {
  const response = await fetch(`${API_BASE}/todos/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(data)
  });

  return handleResponse(response);
}

/**
 * Deletes a todo by ID
 * @param {string} id - Todo ID
 * @returns {Promise<void>}
 */
async function deleteTodo(id) {
  const response = await fetch(`${API_BASE}/todos/${encodeURIComponent(id)}`, {
    method: 'DELETE'
  });

  return handleResponse(response);
}

module.exports = {
  createTodo,
  getAllTodos,
  getTodo,
  updateTodo,
  deleteTodo
};
