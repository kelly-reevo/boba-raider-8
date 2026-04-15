/**
 * Add Todo Submit Handler
 *
 * Handles form submission from add-todo-form.
 * Validates input, calls create operation, clears input, re-renders list.
 */

/**
 * Handles form submit or Enter key events for adding a todo.
 *
 * @param {Event|KeyboardEvent} event - The submit or keydown event
 * @param {HTMLInputElement} input - The todo title input element
 * @param {HTMLElement} todoListContainer - The container for the todo list
 * @param {Function} createFn - Function to create a todo (todo-store-create)
 * @param {Function} renderFn - Function to re-render the todo list
 */
export function handleAddTodoSubmit(event, input, todoListContainer, createFn, renderFn) {
  // Prevent default form submission or key behavior
  if (event.cancelable) {
    event.preventDefault();
  }

  // Handle Enter key - only process if it's Enter or NumpadEnter without Shift
  if (event.type === 'keydown') {
    const keyEvent = /** @type {KeyboardEvent} */ (event);
    if (keyEvent.key !== 'Enter' && keyEvent.key !== 'NumpadEnter') {
      return;
    }
    if (keyEvent.shiftKey) {
      return;
    }
  }

  // Get and trim the input value
  const rawValue = input.value;
  const trimmedValue = rawValue.trim();

  // Clear any existing validation error
  clearValidationError();

  // Validate input is not empty (after trimming)
  if (trimmedValue === '') {
    showValidationError('Todo title cannot be empty');
    return;
  }

  // Call the create function with trimmed value
  createFn(trimmedValue);

  // Clear the input
  input.value = '';

  // Re-render the todo list
  renderFn(todoListContainer);
}

/**
 * Initialize the add todo form with event listeners.
 *
 * @param {HTMLFormElement} form - The add todo form element
 * @param {HTMLInputElement} input - The todo title input element
 * @param {HTMLElement} todoListContainer - The container for the todo list
 * @param {Function} createFn - Function to create a todo
 * @param {Function} renderFn - Function to re-render the todo list
 */
export function initAddTodoForm(form, input, todoListContainer, createFn, renderFn) {
  // Handle form submission
  form.addEventListener('submit', (event) => {
    handleAddTodoSubmit(event, input, todoListContainer, createFn, renderFn);
  });

  // Handle Enter key in input field
  input.addEventListener('keydown', (event) => {
    handleAddTodoSubmit(event, input, todoListContainer, createFn, renderFn);
  });
}

/**
 * Clear any existing validation error message.
 */
function clearValidationError() {
  const existingError = document.querySelector('[data-testid="validation-error"]');
  if (existingError && existingError.parentNode) {
    existingError.parentNode.removeChild(existingError);
  }
}

/**
 * Show a validation error message.
 *
 * @param {string} message - The error message to display
 */
function showValidationError(message) {
  // Check if error element already exists
  let errorElement = document.querySelector('[data-testid="validation-error"]');

  if (!errorElement) {
    // Create new error element
    errorElement = document.createElement('div');
    errorElement.setAttribute('data-testid', 'validation-error');
    errorElement.style.color = 'red';
    errorElement.style.marginTop = '4px';

    // Insert after the input or its form
    const form = document.querySelector('[data-testid="add-todo-form"]');
    if (form) {
      form.appendChild(errorElement);
    } else {
      document.body.appendChild(errorElement);
    }
  }

  errorElement.textContent = message;
  errorElement.style.display = 'block';
}
