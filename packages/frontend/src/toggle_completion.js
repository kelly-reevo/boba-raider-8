/**
 * Toggle completion handler for todo items
 * Manages checkbox state with optimistic updates and error handling
 */

import { updateTodo } from './http_client.js';

const pendingRequests = new Map();

/**
 * Initialize toggle completion handling on a container element
 * Uses event delegation for efficient handling of dynamic content
 * @param {HTMLElement} container - The container element (e.g., #todo-list)
 */
export function initToggleCompletion(container) {
  if (!container) {
    console.error('Toggle completion: Container element not found');
    return;
  }

  // Use change event for checkbox state changes (fires after the checked state updates)
  container.addEventListener('change', handleCheckboxChange);
}

/**
 * Handle checkbox change events
 * @param {Event} event - The change event
 */
async function handleCheckboxChange(event) {
  const checkbox = event.target;

  // Only handle checkbox inputs with data-id attribute
  if (!checkbox.matches('input[type="checkbox"]') || !checkbox.hasAttribute('data-id')) {
    return;
  }

  const id = checkbox.getAttribute('data-id');
  // At change event, checkbox.checked already reflects the NEW state
  const newCompleted = checkbox.checked;
  const originalState = !newCompleted;

  // Find related elements
  const todoItem = findTodoItem(checkbox, id);
  const loadingIndicator = findLoadingIndicator(id);
  const errorNotification = document.querySelector('[data-testid="error-notification"]');

  // Check if there's already a pending request for this todo
  if (pendingRequests.has(id)) {
    // Prevent conflicting updates by reverting to pending state
    event.preventDefault();
    return;
  }

  // Set loading state
  setLoadingState(checkbox, todoItem, loadingIndicator, true);

  // Create the request promise
  const requestPromise = updateTodo(id, { completed: newCompleted });
  pendingRequests.set(id, requestPromise);

  try {
    await requestPromise;
    // Success: checkbox stays in new state (already set by the change event)
    hideError(errorNotification);
  } catch (error) {
    // Error: revert checkbox to original state
    checkbox.checked = originalState;
    showError(errorNotification, 'Failed to update todo');
  } finally {
    // Clear loading state
    setLoadingState(checkbox, todoItem, loadingIndicator, false);
    pendingRequests.delete(id);
  }
}

/**
 * Create a handler function for inline use in the application
 * This can be attached directly to the todo list container
 * Handles both click and change events for maximum compatibility
 * @returns {Function} Event handler function
 */
export function createToggleHandler() {
  const pendingRequests = new Map();
  const processingCheckboxes = new WeakSet();

  return async function handleToggleEvent(event) {
    const checkbox = event.target;

    // Only handle checkbox inputs with data-id attribute
    if (!checkbox.matches('input[type="checkbox"]') || !checkbox.hasAttribute('data-id')) {
      return;
    }

    // Prevent duplicate processing of the same checkbox
    if (processingCheckboxes.has(checkbox)) {
      return;
    }

    const id = checkbox.getAttribute('data-id');

    // Determine the new completed state based on event type
    let newCompleted;
    let originalState;

    if (event.type === 'change') {
      // Change event: checkbox.checked already reflects the new state
      newCompleted = checkbox.checked;
      originalState = !newCompleted;
    } else if (event.type === 'click') {
      // Click event: checkbox.checked hasn't changed yet, so invert it
      originalState = checkbox.checked;
      newCompleted = !originalState;

      // Optimistically update the checkbox state
      checkbox.checked = newCompleted;
    } else {
      return;
    }

    const todoItem = document.querySelector(`[data-testid="todo-item-${id}"]`) ||
                     checkbox.closest('.todo-item');
    const loadingIndicator = document.querySelector(`[data-testid="todo-loading-${id}"]`);
    const errorNotification = document.querySelector('[data-testid="error-notification"]');

    // Check for conflicting requests
    if (pendingRequests.has(id)) {
      checkbox.checked = originalState;
      return;
    }

    processingCheckboxes.add(checkbox);

    // Set loading state
    checkbox.disabled = true;
    if (todoItem) todoItem.classList.add('updating');
    if (loadingIndicator) loadingIndicator.style.display = 'inline';

    const requestPromise = updateTodo(id, { completed: newCompleted });
    pendingRequests.set(id, requestPromise);

    try {
      await requestPromise;
      if (errorNotification) {
        errorNotification.style.display = 'none';
        errorNotification.textContent = '';
      }
    } catch (error) {
      // Revert to original state on error
      checkbox.checked = originalState;
      if (errorNotification) {
        errorNotification.textContent = 'Failed to update todo';
        errorNotification.style.display = 'block';
      }
    } finally {
      checkbox.disabled = false;
      if (todoItem) todoItem.classList.remove('updating');
      if (loadingIndicator) loadingIndicator.style.display = 'none';
      pendingRequests.delete(id);
      processingCheckboxes.delete(checkbox);
    }
  };
}

/**
 * Find the parent todo item element
 * @param {HTMLElement} checkbox - The checkbox element
 * @param {string} id - The todo ID
 * @returns {HTMLElement|null}
 */
function findTodoItem(checkbox, id) {
  return document.querySelector(`[data-testid="todo-item-${id}"]`) ||
         checkbox.closest('.todo-item') ||
         checkbox.parentElement;
}

/**
 * Find the loading indicator for a todo
 * @param {string} id - The todo ID
 * @returns {HTMLElement|null}
 */
function findLoadingIndicator(id) {
  return document.querySelector(`[data-testid="todo-loading-${id}"]`);
}

/**
 * Set the loading state for a todo item
 * @param {HTMLInputElement} checkbox - The checkbox element
 * @param {HTMLElement|null} todoItem - The todo item container
 * @param {HTMLElement|null} loadingIndicator - The loading indicator element
 * @param {boolean} isLoading - Whether the item is loading
 */
function setLoadingState(checkbox, todoItem, loadingIndicator, isLoading) {
  checkbox.disabled = isLoading;

  if (todoItem) {
    if (isLoading) {
      todoItem.classList.add('updating');
    } else {
      todoItem.classList.remove('updating');
    }
  }

  if (loadingIndicator) {
    loadingIndicator.style.display = isLoading ? 'inline' : 'none';
  }
}

/**
 * Show error notification
 * @param {HTMLElement|null} errorNotification - The error notification element
 * @param {string} message - The error message
 */
function showError(errorNotification, message) {
  if (errorNotification) {
    errorNotification.textContent = message;
    errorNotification.style.display = 'block';
  }
}

/**
 * Hide error notification
 * @param {HTMLElement|null} errorNotification - The error notification element
 */
function hideError(errorNotification) {
  if (errorNotification) {
    errorNotification.style.display = 'none';
    errorNotification.textContent = '';
  }
}

/**
 * Clean up event listeners (useful for testing)
 * @param {HTMLElement} container - The container element
 */
export function cleanupToggleCompletion(container) {
  if (container) {
    container.removeEventListener('change', handleCheckboxChange);
  }
  pendingRequests.clear();
}
