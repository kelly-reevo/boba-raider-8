import { initTodoStore, getTodos, getAllTodos } from './todo_store.js';
import { renderList, renderCounter } from './render.js';
import { initDeleteHandlers } from './delete_handler.js';

let store = null;

/**
 * Initialize the application
 * @returns {Object} App API
 */
export function initializeApp() {
  // Use existing store if already initialized (singleton pattern)
  if (!store) {
    store = initTodoStore();
  }

  // Subscribe to store changes to re-render
  store.subscribe(() => {
    renderApp();
  });

  // Initial render
  renderApp();

  // Bind delete handlers
  initDeleteHandlers();

  return {
    store,
    render: renderApp,
  };
}

/**
 * Render the app with current state
 * Used for re-rendering after state changes
 */
export function renderApp() {
  // Get filtered todos for list display
  const todos = getTodos();

  // Get all todos to count active items
  const allTodos = getAllTodos();
  const activeCount = allTodos.filter(t => !t.completed).length;

  // Render list and counter
  renderList(todos);
  renderCounter(activeCount);

  // Re-bind delete handlers
  initDeleteHandlers();
}

/**
 * Get the store instance
 * @returns {Object} Store instance
 */
export function getStore() {
  return store;
}
