/**
 * Delete Todo Handler
 *
 * Handles delete button clicks on todo items. Attaches click handlers to delete buttons,
 * extracts todo id, calls http-client.deleteTodo, removes item from DOM on success,
 * and shows error on failure.
 */

import { deleteTodo } from './http_client.js';

// Track in-progress deletions to prevent duplicates
const inProgress = new Set();

/**
 * Extract todo ID from a delete button element
 * The button should have data-testid="delete-todo-btn-{id}"
 * @param {HTMLElement} button - The delete button element
 * @returns {string|null} - The todo ID or null if not found
 */
function extractTodoId(button) {
  const testId = button.getAttribute('data-testid');
  if (!testId) return null;

  // Parse pattern: delete-todo-btn-{id}
  const match = testId.match(/^delete-todo-btn-(.+)$/);
  return match ? match[1] : null;
}

/**
 * Show error message in the error display element
 * @param {string} message - The error message to display
 */
function showError(message) {
  const errorElement = document.querySelector('[data-testid="delete-error-message"]');
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.classList.remove('hidden');
  }
}

/**
 * Hide error message display
 */
function hideError() {
  const errorElement = document.querySelector('[data-testid="delete-error-message"]');
  if (errorElement) {
    errorElement.classList.add('hidden');
    errorElement.textContent = '';
  }
}

/**
 * Remove todo item from DOM
 * @param {string} todoId - The ID of the todo to remove
 */
function removeTodoElement(todoId) {
  const todoElement = document.querySelector(`[data-testid="todo-item-${todoId}"]`);
  if (todoElement) {
    todoElement.remove();
  }
}

/**
 * Check if all todos have been deleted and show empty state if needed
 */
function checkEmptyState() {
  const todoItems = document.querySelectorAll('[data-testid^="todo-item-"]');
  const emptyState = document.querySelector('[data-testid="empty-state"]');

  if (todoItems.length === 0 && emptyState) {
    emptyState.classList.remove('hidden');
  }
}

/**
 * Handle the delete operation for a specific todo
 * @param {string} todoId - The ID of the todo to delete
 * @returns {Promise<{status: string, response?: any, error?: any, reason?: string}>}
 */
export async function handleDelete(todoId) {
  // Prevent duplicate requests
  if (inProgress.has(todoId)) {
    return { status: 'ignored' };
  }

  inProgress.add(todoId);
  hideError();

  try {
    const response = await deleteTodo(todoId);
    inProgress.delete(todoId);

    // Remove from DOM on success (204)
    removeTodoElement(todoId);
    checkEmptyState();

    return { status: 'success', response };
  } catch (error) {
    inProgress.delete(todoId);

    if (error.status === 404) {
      // Already gone, remove from DOM anyway
      removeTodoElement(todoId);
      checkEmptyState();
      return { status: 'removed', reason: 'already_gone' };
    }

    // Show error for other failures (500, 403, 401, network errors, etc.)
    const errorMessage = error.message || 'Unknown error';
    showError(`Failed to delete todo: ${errorMessage}`);

    return { status: 'error', error };
  }
}

/**
 * Create click handler for a delete button
 * @param {HTMLElement} button - The delete button element
 * @returns {Function} - Event handler function
 */
function createClickHandler(button) {
  return async (event) => {
    event.preventDefault();

    const todoId = extractTodoId(button);
    if (!todoId) return;

    await handleDelete(todoId);
  };
}

/**
 * Attach delete handlers to all delete buttons in the document
 * Call this after rendering the todo list
 */
export function attachDeleteHandlers() {
  const deleteButtons = document.querySelectorAll('[data-testid^="delete-todo-btn-"]');

  deleteButtons.forEach((button) => {
    // Remove existing listener if any (prevents duplicates)
    if (button._deleteHandler) {
      button.removeEventListener('click', button._deleteHandler);
    }

    // Create and attach new handler
    const handler = createClickHandler(button);
    button._deleteHandler = handler;
    button.addEventListener('click', handler);
  });
}

/**
 * Attach delete handler to a specific todo item or button
 * @param {string} todoId - The todo ID to attach handler for
 */
export function attachDeleteHandlerForTodo(todoId) {
  const button = document.querySelector(`[data-testid="delete-todo-btn-${todoId}"]`);
  if (!button) return;

  // Remove existing listener if any
  if (button._deleteHandler) {
    button.removeEventListener('click', button._deleteHandler);
  }

  // Create and attach new handler
  const handler = createClickHandler(button);
  button._deleteHandler = handler;
  button.addEventListener('click', handler);
}

/**
 * Initialize delete handlers and set up mutation observer for dynamic content
 */
export function initDeleteHandlers() {
  // Attach to existing buttons
  attachDeleteHandlers();

  // Watch for new todo items being added to the DOM
  const observer = new MutationObserver((mutations) => {
    let shouldAttach = false;

    for (const mutation of mutations) {
      if (mutation.type === 'childList') {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if added node is or contains a delete button
            if (node.hasAttribute && node.hasAttribute('data-testid')) {
              const testId = node.getAttribute('data-testid');
              if (testId && testId.startsWith('delete-todo-btn-')) {
                shouldAttach = true;
                break;
              }
            }
            if (node.querySelector && node.querySelector('[data-testid^="delete-todo-btn-"]')) {
              shouldAttach = true;
              break;
            }
          }
        }
      }
    }

    if (shouldAttach) {
      attachDeleteHandlers();
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });

  return observer;
}

export default {
  handleDelete,
  attachDeleteHandlers,
  attachDeleteHandlerForTodo,
  initDeleteHandlers,
  extractTodoId,
};
