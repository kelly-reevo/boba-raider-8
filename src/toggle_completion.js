/**
 * Toggle completion handler for todo items.
 * Uses event delegation on #todo-list to handle checkbox changes.
 * Calls API to update completion status and updates UI accordingly.
 */

import { updateTodo } from './api.js';

/**
 * Initialize the toggle completion handler.
 * Sets up event delegation on the todo list container.
 */
export function initToggleCompletion() {
  const todoList = document.querySelector('#todo-list');

  if (!todoList) {
    console.error('Toggle completion: #todo-list container not found');
    return;
  }

  todoList.addEventListener('change', handleCheckboxChange);
}

/**
 * Handle checkbox change events via event delegation.
 * @param {Event} event - The change event
 */
async function handleCheckboxChange(event) {
  const checkbox = event.target;

  // Only handle checkbox inputs within todo items
  if (checkbox.type !== 'checkbox' || !checkbox.hasAttribute('data-todo-id')) {
    return;
  }

  const todoId = checkbox.getAttribute('data-todo-id');
  const todoItem = checkbox.closest('.todo-item');
  const errorMessage = document.querySelector('#error-message');

  if (!todoId) {
    console.error('Toggle completion: No data-todo-id found on checkbox');
    return;
  }

  // Store previous state for potential revert
  const previousChecked = !checkbox.checked;
  const newCompletedState = checkbox.checked;

  try {
    // Call API to update completion status
    const updatedTodo = await updateTodo(todoId, { completed: newCompletedState });

    // On success: toggle completed class on parent item
    if (todoItem) {
      if (newCompletedState) {
        todoItem.classList.add('completed');
      } else {
        todoItem.classList.remove('completed');
      }
    }

    // Hide any previous error message
    if (errorMessage) {
      errorMessage.style.display = 'none';
      errorMessage.textContent = '';
    }

  } catch (error) {
    // On error: revert checkbox to previous state
    checkbox.checked = previousChecked;

    // Display error message
    if (errorMessage) {
      errorMessage.textContent = error.message || 'Failed to update todo. Please try again.';
      errorMessage.style.display = 'block';
    }

    console.error('Toggle completion failed:', error);
  }
}

// Auto-initialize when DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initToggleCompletion);
  } else {
    // DOM already loaded, initialize immediately
    initToggleCompletion();
  }
}
