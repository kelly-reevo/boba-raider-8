/**
 * Delete Todo Handler
 *
 * Handles delete button clicks with event delegation pattern.
 * - Shows confirmation dialog
 * - Calls deleteTodo API
 * - Removes item from DOM on success
 * - Shows error message on failure
 */

/**
 * Initialize the delete handler by attaching event delegation listener
 */
export function initDeleteHandler() {
  document.addEventListener('click', handleDeleteClick);
}

/**
 * Handle click events on delete buttons
 * @param {MouseEvent} event
 */
async function handleDeleteClick(event) {
  // Use event delegation - find closest .delete-btn ancestor
  const btn = event.target.closest('.delete-btn');
  if (!btn) return;

  // Find the todo item container with the todo ID
  const todoItem = btn.closest('[data-todo-id]');
  if (!todoItem) return;

  const todoId = todoItem.getAttribute('data-todo-id');
  if (!todoId) return;

  // Show confirmation dialog
  const confirmed = confirm('Are you sure you want to delete this todo?');
  if (!confirmed) {
    // User cancelled - do nothing
    return;
  }

  // Disable button during request
  btn.disabled = true;

  try {
    // Get httpClient from global scope
    const httpClient = globalThis.httpClient;
    if (!httpClient || typeof httpClient.deleteTodo !== 'function') {
      throw new Error('HTTP client not available');
    }

    // Call delete API
    await httpClient.deleteTodo(todoId);

    // Success - remove todo item from DOM
    todoItem.remove();
  } catch (error) {
    // Error - re-enable button
    btn.disabled = false;

    // Show error message in #list-error container
    const errorEl = document.querySelector('#list-error') ||
                    document.querySelector('[data-testid="list-error"]');
    if (errorEl) {
      errorEl.textContent = 'Failed to delete todo. Please try again.';
      errorEl.style.display = 'block';
    }

    // Log error for debugging
    console.error('Failed to delete todo:', error);
  }
}

// Auto-initialize when DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initDeleteHandler);
  } else {
    // DOM already loaded, initialize immediately
    initDeleteHandler();
  }
}

// Export for testing
export { handleDeleteClick };
