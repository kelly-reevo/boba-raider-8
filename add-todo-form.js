/**
 * Add Todo Form handler
 * Handles form submission, validation, and API integration
 */

import { createTodo } from './api-client.js';
import { refreshTodoList } from './todo-list.js';

/**
 * Sets up event handlers for the add-todo-form
 * Attaches submit handler that prevents default, validates, and calls API
 */
export function setupAddTodoForm() {
  const form = document.getElementById('add-todo-form');
  if (!form) return;

  form.addEventListener('submit', handleFormSubmit);
}

/**
 * Handles the form submit event
 * @param {Event} event - The submit event
 */
async function handleFormSubmit(event) {
  event.preventDefault();

  const form = event.target;
  const titleInput = document.getElementById('todo-title');
  const descriptionInput = document.getElementById('todo-description');
  const titleError = document.getElementById('title-error');

  // Clear previous errors
  clearErrors();

  // Validate: Check HTML5 validity (required attribute)
  if (!titleInput.validity.valid) {
    // HTML5 validation prevents submission - don't call API
    return;
  }

  // Extract and prepare form data
  const title = titleInput.value.trim();
  const description = descriptionInput.value.trim();

  // Additional validation: empty/whitespace-only title
  if (!title) {
    return;
  }

  const formData = {
    title: title,
    description: description || null,
  };

  try {
    const result = await createTodo(formData);

    // Check if result contains an error (API returned error in body)
    if (result.error) {
      // Don't clear form on error
      return;
    }

    // Success: Clear form inputs
    titleInput.value = '';
    descriptionInput.value = '';

    // Trigger list refresh
    refreshTodoList();
  } catch (error) {
    // Handle validation errors (422) or other errors
    displayErrors(error, titleError);
  }
}

/**
 * Clears all error messages from the form
 */
function clearErrors() {
  const errorElements = document.querySelectorAll('.error-message, .form-error, #title-error, #description-error');
  errorElements.forEach(el => {
    el.textContent = '';
    el.classList.remove('visible');
  });
}

/**
 * Displays error messages from API response
 * @param {Error} error - The error object from API
 * @param {HTMLElement} titleErrorElement - The element to display title errors in
 */
function displayErrors(error, titleErrorElement) {
  // Determine the error display element
  const errorDisplay = titleErrorElement || document.querySelector('.form-error');

  if (error.status === 422 && error.errors) {
    // Validation error with field-specific messages
    if (error.errors.title && errorDisplay) {
      errorDisplay.textContent = error.errors.title;
      errorDisplay.classList.add('visible');
    } else if (error.message && errorDisplay) {
      // Generic validation message with field errors object
      errorDisplay.textContent = error.message;
      errorDisplay.classList.add('visible');
    }
  } else if (error.message) {
    // Generic error message
    if (errorDisplay) {
      errorDisplay.textContent = error.message;
      errorDisplay.classList.add('visible');
    }
  } else {
    // Network or unknown error
    if (errorDisplay) {
      errorDisplay.textContent = 'Network error. Please try again.';
      errorDisplay.classList.add('visible');
    }
  }
}
