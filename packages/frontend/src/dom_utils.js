/**
 * DOM Utilities for Todo List UI
 * Helper functions for DOM manipulation and querying
 */

/**
 * Query an element by its data-testid attribute
 * @param {string} testId - The data-testid value
 * @param {ParentNode} [parent=document] - Optional parent element to search within
 * @returns {Element|null} The found element or null
 */
export function getByTestId(testId, parent = document) {
  return parent.querySelector(`[data-testid="${testId}"]`);
}

/**
 * Query all elements with a data-testid attribute
 * @param {string} testId - The data-testid value
 * @param {ParentNode} [parent=document] - Optional parent element to search within
 * @returns {NodeList} List of matching elements
 */
export function getAllByTestId(testId, parent = document) {
  return parent.querySelectorAll(`[data-testid="${testId}"]`);
}

/**
 * Remove a todo item element from the DOM by its ID
 * @param {string} todoId - The todo ID (data-todo-id value)
 * @returns {boolean} True if element was found and removed, false otherwise
 */
export function removeTodoElement(todoId) {
  const todoElement = getByTestId(`todo-item-${todoId}`);
  if (todoElement) {
    todoElement.remove();
    return true;
  }
  return false;
}

/**
 * Show the empty state element when no todos remain
 * @returns {boolean} True if empty state was shown, false if already visible or not found
 */
export function showEmptyState() {
  const emptyState = getByTestId('empty-state');
  const todoList = getByTestId('todo-list');

  if (!emptyState) return false;

  // Check if there are any remaining todo items
  const remainingTodos = todoList ? todoList.querySelectorAll('[data-todo-id]') : [];

  if (remainingTodos.length === 0) {
    emptyState.classList.remove('hidden');
    emptyState.style.display = 'flex';
    return true;
  }

  return false;
}

/**
 * Display an error message in the error container
 * @param {string} message - The error message to display
 * @returns {boolean} True if error element was found and updated
 */
export function showErrorMessage(message) {
  const errorElement = getByTestId('error-message');
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.classList.remove('hidden');
    if (errorElement.style) {
      errorElement.style.display = 'block';
    }
    return true;
  }
  return false;
}

/**
 * Hide the error message container
 * @returns {boolean} True if error element was found and hidden
 */
export function hideErrorMessage() {
  const errorElement = getByTestId('error-message');
  if (errorElement) {
    errorElement.classList.add('hidden');
    if (errorElement.style) {
      errorElement.style.display = 'none';
    }
    return true;
  }
  return false;
}

/**
 * Extract the todo ID from a delete button element
 * Uses the closest ancestor with data-todo-id attribute
 * @param {Element} deleteBtn - The delete button element
 * @returns {string|null} The todo ID or null if not found
 */
export function extractTodoId(deleteBtn) {
  const todoItem = deleteBtn.closest('[data-todo-id]');
  if (todoItem) {
    return todoItem.getAttribute('data-todo-id');
  }
  return null;
}
