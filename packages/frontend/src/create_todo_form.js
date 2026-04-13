/**
 * Create Todo Form Handler
 *
 * Handles form submission for creating new todos:
 * - Captures submit event on #add-todo-form
 * - Extracts title and description from form inputs
 * - Validates title is non-empty
 * - Calls http-client.createTodo to submit data
 * - Shows validation errors inline
 * - Clears form on success and triggers list refresh
 * - Displays error messages on API failure
 */

import { createTodo } from './http_client.js';
import { refresh } from './todo_list_renderer.js';

/**
 * Initialize the create todo form handler
 * Attaches submit event listener to the form
 */
export function initCreateTodoForm() {
  const form = document.querySelector('[data-testid="add-todo-form"]');
  if (!form) {
    return;
  }

  // Remove existing listener to avoid duplicates
  form.removeEventListener('submit', handleSubmit);
  form.addEventListener('submit', handleSubmit);
}

/**
 * Handle form submission
 * @param {Event} event - The submit event
 */
async function handleSubmit(event) {
  event.preventDefault();

  const form = event.target;
  const titleInput = form.querySelector('[data-testid="todo-title-input"]');
  const descriptionInput = form.querySelector('[data-testid="todo-description-input"]');

  if (!titleInput) {
    return;
  }

  const title = titleInput.value.trim();
  const description = (descriptionInput?.value || '').trim();

  // Clear previous errors
  clearErrors(form);

  // Client-side validation
  if (!title) {
    showValidationError(form, 'Title is required');
    return;
  }

  try {
    const response = await createTodo({ title, description });

    if (response.ok) {
      // Success: clear form and refresh list
      form.reset();
      await refresh();
    } else if (response.status === 422) {
      // Server validation error
      const data = await response.json();
      const errorMessage = extractServerError(data);
      showServerError(form, errorMessage);
    } else {
      // Other HTTP errors
      const errorText = await response.text();
      showApiError(form, errorText || `Server error: ${response.status}`);
    }
  } catch (error) {
    // Network or other errors - keep form values and show error
    showApiError(form, error.message || 'Network error');
  }
}

/**
 * Show client-side validation error
 * @param {HTMLFormElement} form - The form element
 * @param {string} message - Error message
 */
function showValidationError(form, message) {
  const errorEl = form.querySelector('[data-testid="title-validation-error"]');
  if (errorEl) {
    errorEl.textContent = message;
    errorEl.style.display = 'block';
  }
}

/**
 * Show server validation error
 * @param {HTMLFormElement} form - The form element
 * @param {string} message - Error message
 */
function showServerError(form, message) {
  const errorEl = form.querySelector('[data-testid="server-validation-error"]');
  if (errorEl) {
    errorEl.textContent = message;
    errorEl.style.display = 'block';
  }
}

/**
 * Show API error message
 * @param {HTMLFormElement} form - The form element
 * @param {string} message - Error message
 */
function showApiError(form, message) {
  const errorEl = document.querySelector('[data-testid="create-todo-error-message"]');
  if (errorEl) {
    errorEl.textContent = message;
    errorEl.style.display = 'block';
  }
}

/**
 * Clear all error messages
 * @param {HTMLFormElement} form - The form element
 */
function clearErrors(form) {
  const validationErrorEl = form.querySelector('[data-testid="title-validation-error"]');
  if (validationErrorEl) {
    validationErrorEl.textContent = '';
    validationErrorEl.style.display = 'none';
  }

  const serverErrorEl = form.querySelector('[data-testid="server-validation-error"]');
  if (serverErrorEl) {
    serverErrorEl.textContent = '';
    serverErrorEl.style.display = 'none';
  }

  const apiErrorEl = document.querySelector('[data-testid="create-todo-error-message"]');
  if (apiErrorEl) {
    apiErrorEl.textContent = '';
    apiErrorEl.style.display = 'none';
  }
}

/**
 * Extract error message from server response
 * @param {Object} data - Server error response
 * @returns {string} Error message
 */
function extractServerError(data) {
  if (data.errors && Array.isArray(data.errors) && data.errors.length > 0) {
    return data.errors.map(e => e.message || e).join(', ');
  }
  if (data.message) {
    return data.message;
  }
  if (data.error) {
    return data.error;
  }
  return 'Validation failed';
}

// Auto-initialize if DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCreateTodoForm);
  } else {
    initCreateTodoForm();
  }
}
