/**
 * HTTP client for todo API operations
 */

const API_BASE = '/api';

/**
 * Create a new todo
 * @param {Object} todo - The todo to create
 * @param {string} todo.title - The todo title
 * @param {string} todo.description - The todo description
 * @returns {Promise<Response>} Fetch response
 */
export async function createTodo(todo) {
  const response = await fetch(`${API_BASE}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todo),
  });

  return response;
}

/**
 * Fetch all todos
 * @returns {Promise<Response>} Fetch response
 */
export async function fetchTodos() {
  const response = await fetch(`${API_BASE}/todos`);
  return response;
}
