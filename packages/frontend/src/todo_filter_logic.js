/**
 * Todo Filter Logic Module
 * Manages filter state and filters todo items
 */

// Current filter value: 'all' | 'active' | 'completed'
let currentFilter = 'all';

/**
 * Sets the current filter value
 * @param {string} value - The filter value ('all', 'active', or 'completed')
 */
export function setFilter(value) {
  currentFilter = value;
}

/**
 * Gets the current filter value
 * @returns {string} The current filter value
 */
export function getCurrentFilter() {
  return currentFilter;
}

/**
 * Filters a list of todos based on the current filter
 * @param {Array} todos - Array of todo objects with 'completed' property
 * @returns {Array} Filtered array of todos
 */
export function getFilteredTodos(todos) {
  switch (currentFilter) {
    case 'active':
      return todos.filter(todo => !todo.completed);
    case 'completed':
      return todos.filter(todo => todo.completed);
    case 'all':
    default:
      return todos;
  }
}
