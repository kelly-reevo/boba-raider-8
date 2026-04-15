/**
 * Todo Store Module
 *
 * Provides operations for creating and managing todos.
 * This is the real implementation that would connect to the backend API.
 */

/**
 * Create a new todo with the given title.
 *
 * @param {string} title - The todo title
 * @returns {{id: string, title: string, completed: boolean}} The created todo
 */
export function create(title) {
  // In a real implementation, this would call the backend API
  // For now, return a mock todo object
  return {
    id: `todo-${Date.now()}`,
    title: title,
    completed: false
  };
}
