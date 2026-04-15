import { deleteTodo, getTodos, getAllTodos } from './todo_store.js';
import { renderList, renderCounter } from './render.js';

/**
 * Handle delete button click event
 * @param {string} id - The todo ID to delete
 */
export function handleDeleteClick(id) {
  // Call delete operation on the store
  deleteTodo(id);

  // Get filtered todos for list display (respects filter)
  const todos = getTodos();

  // Get all todos to count active items (ignores filter)
  const allTodos = getAllTodos();

  // Calculate active count from ALL todos (not filtered)
  const activeCount = allTodos.filter(todo => !todo.completed).length;

  // Re-render the list container
  renderList(todos);

  // Re-render the active counter
  renderCounter(activeCount);
}

/**
 * Initialize delete button event listeners
 * Binds click handlers to all delete buttons in the DOM
 */
export function initDeleteHandlers() {
  const deleteButtons = document.querySelectorAll('[data-testid^="delete-btn-"]');

  deleteButtons.forEach(button => {
    // Clone and replace to remove old listeners
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);

    // Add click listener
    newButton.addEventListener('click', handleDeleteButtonClick);
  });
}

/**
 * Internal click handler for delete buttons
 * @param {Event} event
 */
function handleDeleteButtonClick(event) {
  const button = event.currentTarget;
  const id = button.getAttribute('data-id');

  if (id) {
    handleDeleteClick(id);
  }
}
