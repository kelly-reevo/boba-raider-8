/**
 * Toggle Completion Handler
 *
 * Handles checkbox change events for toggling todo completion status.
 * Uses event delegation for efficient event handling on dynamic lists.
 *
 * Boundary contracts:
 * - Event delegation on .toggle-btn change -> reads data-todo-id
 * - Calls updateTodo(id, {completed: !currentState})
 * - Disables checkbox during request to prevent double-clicks
 * - On success: toggles visual completed state (strikethrough)
 * - On error: restores checkbox state, shows error in #list-error element
 */

import { updateTodo } from './api_client.js';

/**
 * Handle checkbox change events
 * @param {Event} event - The change event
 */
async function handleToggleChange(event) {
  const checkbox = event.target;

  // Only handle toggle-btn class checkboxes
  if (!checkbox.classList.contains('toggle-btn')) {
    return;
  }

  // Only handle checkbox inputs
  if (checkbox.type !== 'checkbox') {
    return;
  }

  // Skip if already disabled (prevents double-handling)
  if (checkbox.disabled) {
    return;
  }

  const todoId = checkbox.getAttribute('data-todo-id');
  if (!todoId) {
    console.error('Toggle completion handler: Checkbox missing data-todo-id');
    return;
  }

  // Store original state for potential reversion
  const originalChecked = !checkbox.checked;
  const newCompletedState = checkbox.checked;

  // Disable checkbox immediately to prevent double-clicks
  checkbox.disabled = true;

  // Find related elements
  // The checkbox itself has data-todo-id, so we need to go up to find the container
  const todoItem = checkbox.parentElement;
  const todoText = todoItem?.querySelector('[data-testid="todo-text"]');
  const errorDiv = document.getElementById('list-error');

  try {
    // Call API to update completion status
    const result = await updateTodo(todoId, { completed: newCompletedState });

    // On success: update visual state
    if (result.completed) {
      todoItem?.classList.add('todo-completed');
      todoText?.classList.add('completed-text');
    } else {
      todoItem?.classList.remove('todo-completed');
      todoText?.classList.remove('completed-text');
    }

    // Ensure checkbox state matches server response
    checkbox.checked = result.completed;

    // Clear any existing error message
    if (errorDiv) {
      errorDiv.textContent = '';
      errorDiv.style.display = 'none';
      errorDiv.classList.add('hidden');
    }

  } catch (error) {
    // On error: restore checkbox to original state
    checkbox.checked = originalChecked;

    // Restore visual state
    if (originalChecked) {
      todoItem?.classList.add('todo-completed');
      todoText?.classList.add('completed-text');
    } else {
      todoItem?.classList.remove('todo-completed');
      todoText?.classList.remove('completed-text');
    }

    // Display error message
    if (errorDiv) {
      let errorMessage = 'Failed to update todo. Please try again.';

      if (error.status === 404) {
        errorMessage = 'Todo not found. It may have been deleted.';
        // Remove the item from DOM since it no longer exists
        todoItem?.remove();
      } else if (error.message?.includes('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (error.status >= 500) {
        errorMessage = 'Server error. Please try again later.';
      }

      errorDiv.textContent = errorMessage;
      errorDiv.style.display = 'block';
      errorDiv.classList.remove('hidden');
    }

    console.error('Toggle completion error:', error);

  } finally {
    // Re-enable checkbox
    checkbox.disabled = false;
    checkbox.focus();
  }
}

/**
 * Initialize the toggle completion handler with event delegation
 * @param {HTMLElement} container - The container element to attach delegation (e.g., todo-list)
 */
export function initToggleCompletionHandler(container) {
  if (!container) {
    console.error('Toggle completion handler: No container provided');
    return;
  }

  container.addEventListener('change', handleToggleChange);
}

/**
 * Cleanup function to remove event listener
 * @param {HTMLElement} container - The container element
 */
export function cleanupToggleCompletionHandler(container) {
  if (container) {
    container.removeEventListener('change', handleToggleChange);
  }
}

export { handleToggleChange };
