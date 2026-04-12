/**
 * API Client for Todo API
 *
 * Wraps fetch API with proper headers, JSON parsing, and error handling.
 * All functions return Promises that resolve to typed data or throw Error on HTTP error status.
 */

const API_BASE_URL = '/api';

/**
 * Error thrown when API returns non-2xx status
 */
class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

/**
 * Helper to make API requests with consistent error handling
 * @param {string} endpoint - API endpoint path (without base)
 * @param {Object} options - Fetch options
 * @returns {Promise<any>} Parsed JSON response
 * @throws {ApiError} When response status is not ok
 */
async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;

  const fetchOptions = {
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    ...options,
  };

  // Add body JSON serialization if provided
  if (options.body && typeof options.body === 'object') {
    fetchOptions.body = JSON.stringify(options.body);
  }

  try {
    const response = await fetch(url, fetchOptions);

    if (!response.ok) {
      // Try to extract error message from response body
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      try {
        const errorBody = await response.json();
        if (errorBody.error) {
          errorMessage = errorBody.error;
        }
      } catch {
        // If JSON parsing fails, use default message
      }
      throw new ApiError(response.status, errorMessage);
    }

    // Handle 204 No Content (e.g., DELETE success)
    if (response.status === 204) {
      return undefined;
    }

    // Parse JSON response
    return await response.json();
  } catch (error) {
    // Re-throw ApiError as-is
    if (error instanceof ApiError) {
      throw error;
    }

    // Network-level failure - propagate with meaningful message
    throw new Error(`Network error: ${error.message}`);
  }
}

/**
 * Creates a new todo item
 * @param {Object} data - Todo creation data
 * @param {string} data.title - Required title (max 200 chars)
 * @param {string} [data.description] - Optional description (max 1000 chars)
 * @param {string} [data.priority] - Optional priority ('low', 'medium', 'high')
 * @returns {Promise<Todo>} Created todo with id, timestamps
 * @throws {ApiError} On validation error (400) or server error (500)
 */
export async function createTodo(data) {
  const body = {
    title: data.title,
  };

  if (data.description !== undefined) {
    body.description = data.description;
  }

  if (data.priority !== undefined) {
    body.priority = data.priority;
  }

  return await apiRequest('/todos', {
    method: 'POST',
    body,
  });
}

/**
 * Retrieves all todos with optional filtering
 * @param {Object} [options] - Query options
 * @param {string} [options.filter] - Filter by status ('all', 'active', 'completed')
 * @returns {Promise<Todo[]>} Array of todos (empty if none exist)
 * @throws {ApiError} On API error
 */
export async function getAllTodos(options = {}) {
  const params = new URLSearchParams();

  if (options.filter !== undefined) {
    params.append('filter', options.filter);
  }

  const queryString = params.toString();
  const endpoint = queryString ? `/todos?${queryString}` : '/todos';

  return await apiRequest(endpoint, {
    method: 'GET',
  });
}

/**
 * Retrieves a single todo by ID
 * @param {string} id - Todo ID
 * @returns {Promise<Todo>} The requested todo
 * @throws {ApiError} With 404 status when todo not found
 */
export async function getTodo(id) {
  return await apiRequest(`/todos/${encodeURIComponent(id)}`, {
    method: 'GET',
  });
}

/**
 * Updates a todo with partial or full data
 * @param {string} id - Todo ID
 * @param {Object} data - Update data (partial updates supported)
 * @param {string} [data.title] - New title
 * @param {string} [data.description] - New description
 * @param {boolean} [data.completed] - New completion status
 * @returns {Promise<Todo>} Updated todo
 * @throws {ApiError} With 404 when todo not found, 400 on validation error
 */
export async function updateTodo(id, data) {
  return await apiRequest(`/todos/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: data,
  });
}

/**
 * Deletes a todo by ID
 * @param {string} id - Todo ID
 * @returns {Promise<void>} Resolves on success
 * @throws {ApiError} With 404 when todo not found, 500 on server error
 */
export async function deleteTodo(id) {
  await apiRequest(`/todos/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

// Default export for convenience
export default {
  createTodo,
  getAllTodos,
  getTodo,
  updateTodo,
  deleteTodo,
};
