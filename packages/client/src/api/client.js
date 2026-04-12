/**
 * API Client for todo operations
 */

const API_BASE = '/api';

/**
 * Create a new todo
 * @param {Object} data - Todo data
 * @param {string} data.title - Todo title (required)
 * @param {string} data.description - Todo description (optional)
 * @returns {Promise<Object>} Created todo object
 */
async function createTodo(data) {
  const response = await fetch(`${API_BASE}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(`Failed to create todo: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Fetch all todos
 * @returns {Promise<Array>} List of todos
 */
async function fetchTodos() {
  const response = await fetch(`${API_BASE}/todos`);

  if (!response.ok) {
    throw new Error(`Failed to fetch todos: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Update a todo
 * @param {string} id - Todo ID
 * @param {Object} data - Todo data to update
 * @returns {Promise<Object>} Updated todo object
 */
async function updateTodo(id, data) {
  const response = await fetch(`${API_BASE}/todos/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(`Failed to update todo: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Delete a todo
 * @param {string} id - Todo ID
 * @returns {Promise<void>}
 */
async function deleteTodo(id) {
  const response = await fetch(`${API_BASE}/todos/${id}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    throw new Error(`Failed to delete todo: ${response.statusText}`);
  }
}

module.exports = {
  createTodo,
  fetchTodos,
  updateTodo,
  deleteTodo,
};
