// DOM Form Handler for new todo form submission
// Handles form validation, submission, and error display

import { createTodo } from './api.js';
import { renderTodos } from './dom_list_renderer.js';

// Form selectors per boundary contract
const FORM_SELECTOR = '#add-todo-form';
const TITLE_INPUT_SELECTOR = 'input[name=title]';
const DESCRIPTION_INPUT_SELECTOR = 'textarea[name=description]';
const ERROR_ELEMENT_ID = 'form-error';
const LIST_SELECTOR = '#todo-list';

/**
 * Initialize the form handler
 * Attaches event listeners to the form
 */
export function initFormHandler() {
  const form = document.querySelector(FORM_SELECTOR);
  if (!form) {
    return;
  }

  // Remove any existing listener to prevent duplicates
  form.removeEventListener('submit', handleSubmit);
  form.addEventListener('submit', handleSubmit);

  // Attach input listener to clear error on title input
  const titleInput = form.querySelector(TITLE_INPUT_SELECTOR);
  if (titleInput) {
    titleInput.removeEventListener('input', handleTitleInput);
    titleInput.addEventListener('input', handleTitleInput);
  }
}

/**
 * Handle title input to clear error messages
 */
function handleTitleInput() {
  const errorDiv = document.getElementById(ERROR_ELEMENT_ID);
  if (errorDiv) {
    errorDiv.textContent = '';
  }
}

/**
 * Refresh the todo list by fetching and re-rendering
 */
async function refreshList() {
  try {
    const { fetchTodos } = await import('./api.js');
    const todos = await fetchTodos();
    renderTodos(todos);
  } catch (error) {
    console.error('Failed to refresh list:', error);
  }
}

/**
 * Handle form submission
 * @param {Event} event - The submit event
 */
async function handleSubmit(event) {
  // Always prevent default form submission
  event.preventDefault();

  const form = event.target;
  const titleInput = form.querySelector(TITLE_INPUT_SELECTOR);
  const descInput = form.querySelector(DESCRIPTION_INPUT_SELECTOR);
  const errorDiv = document.getElementById(ERROR_ELEMENT_ID);

  if (!titleInput) {
    return;
  }

  // Extract form data
  const title = titleInput.value;
  const description = descInput ? descInput.value : '';

  // Client-side validation: title cannot be empty or whitespace-only
  if (!title || title.trim() === '') {
    if (errorDiv) {
      errorDiv.textContent = 'Title is required';
    }
    return;
  }

  // Prepare todo data
  const todoData = {
    title: title,
    description: description,
  };

  try {
    // Call API to create todo
    await createTodo(todoData);

    // On success: clear form inputs
    titleInput.value = '';
    if (descInput) {
      descInput.value = '';
    }

    // Clear any previous error message
    if (errorDiv) {
      errorDiv.textContent = '';
    }

    // Trigger list refresh
    await refreshList();
  } catch (error) {
    // On error: display error message without page reload
    if (errorDiv) {
      const errorMessage = error.errors?.[0]?.message || error.message || 'An error occurred';
      errorDiv.textContent = errorMessage;
    }
    // Form inputs are preserved for user to correct
  }
}
