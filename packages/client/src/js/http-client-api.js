/**
 * HTTP Client API for todo operations
 * Provides functions to interact with the backend API
 */

const API_BASE_URL = 'http://localhost:3000';

/**
 * Fetches the list of todos from the API with optional filter
 * @param {string} filter - Filter type: 'all', 'active', or 'completed'
 * @returns {Promise<Array>} Array of todo objects
 * @throws {Error} When the network request fails
 */
export async function listTodos(filter = 'all') {
  const url = new URL(`${API_BASE_URL}/api/todos`);
  if (filter && filter !== 'all') {
    url.searchParams.append('filter', filter);
  }

  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Failed to fetch todos: ${response.status} ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Creates a new todo via the API
 * @param {Object} todo - The todo to create
 * @param {string} todo.title - The todo title
 * @param {string} [todo.description] - Optional description
 * @param {string} [todo.priority] - Priority level (low, medium, high)
 * @returns {Promise<Object>} The created todo with id
 * @throws {Error} When the network request fails or validation fails
 */
export async function createTodo(todo) {
  const response = await fetch(`${API_BASE_URL}/api/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todo),
  });

  if (!response.ok) {
    throw new Error(`Failed to create todo: ${response.status} ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Updates an existing todo via the API
 * @param {string} id - The todo id
 * @param {Object} updates - The fields to update
 * @returns {Promise<Object>} The updated todo
 * @throws {Error} When the network request fails
 */
export async function updateTodo(id, updates) {
  const response = await fetch(`${API_BASE_URL}/api/todos/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(updates),
  });

  if (!response.ok) {
    throw new Error(`Failed to update todo: ${response.status} ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Deletes a todo via the API
 * @param {string} id - The todo id to delete
 * @returns {Promise<void>}
 * @throws {Error} When the network request fails
 */
export async function deleteTodo(id) {
  const response = await fetch(`${API_BASE_URL}/api/todos/${id}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    throw new Error(`Failed to delete todo: ${response.status} ${response.statusText}`);
  }
}
