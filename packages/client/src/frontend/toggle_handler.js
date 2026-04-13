/**
 * Toggle handler for todo checkboxes
 * Attaches event listeners to handle checkbox toggles
 */

/**
 * Initialize toggle handlers on the document
 * Called when the DOM is ready
 */
export function initToggleHandlers() {
  // Use event delegation for dynamic content
  document.addEventListener('change', handleToggleChange);
}

/**
 * Handle checkbox change events
 * @param {Event} event
 */
function handleToggleChange(event) {
  const checkbox = event.target;

  // Only handle toggles for elements with the 'toggle' class
  if (!checkbox.classList.contains('toggle')) {
    return;
  }

  // Find the parent todo item
  const todoItem = checkbox.closest('.todo-item');
  if (!todoItem) {
    return;
  }

  // Get the todo ID from the data attribute
  const todoId = todoItem.getAttribute('data-id');
  if (!todoId) {
    return;
  }

  // Determine the current state and the new state
  const wasCompleted = checkbox.getAttribute('data-completed') === 'true';
  const newCompleted = checkbox.checked;

  // Optimistically update the UI
  checkbox.setAttribute('data-completed', String(newCompleted));
  if (newCompleted) {
    todoItem.classList.add('completed');
  } else {
    todoItem.classList.remove('completed');
  }

  // Make the PATCH request
  fetch(`/api/todos/${todoId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed: newCompleted })
  })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then(data => {
      // Success - UI already updated optimistically
      clearError();
    })
    .catch(error => {
      // Error - revert the checkbox and UI
      checkbox.checked = wasCompleted;
      checkbox.setAttribute('data-completed', String(wasCompleted));
      if (wasCompleted) {
        todoItem.classList.add('completed');
      } else {
        todoItem.classList.remove('completed');
      }
      showError('error: ' + (error.message || 'Failed to update todo'));
    });
}

/**
 * Show error message
 * @param {string} message
 */
function showError(message) {
  const errorContainer = document.getElementById('error-message');
  if (errorContainer) {
    errorContainer.textContent = message;
    errorContainer.style.display = 'block';
  }
}

/**
 * Clear error message
 */
function clearError() {
  const errorContainer = document.getElementById('error-message');
  if (errorContainer) {
    errorContainer.textContent = '';
    errorContainer.style.display = 'none';
  }
}

// Auto-initialize when DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initToggleHandlers);
  } else {
    initToggleHandlers();
  }
}
