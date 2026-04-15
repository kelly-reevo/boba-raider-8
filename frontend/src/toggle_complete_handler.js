/**
 * Toggle Complete Handler
 *
 * Handles checkbox click events to toggle todo completion status.
 * Calls the store update operation and triggers re-render of affected components.
 *
 * Boundary Contract:
 * - Input: checkbox change event with data-todo-id from parent element
 * - Action: call toggleTodo(id), then re-render affected item and counter
 * - Output: Visual state changes (strikethrough, checked), counter updates
 */

/**
 * Extract todo id from checkbox element by traversing to parent todo-item
 * @param {HTMLInputElement} checkboxElement - The checkbox input element
 * @returns {string|null} - The todo id or null if not found
 */
export function extractTodoId(checkboxElement) {
  const todoItem = checkboxElement.closest('[data-testid^="todo-item-"]');
  if (!todoItem) {
    return null;
  }
  return todoItem.getAttribute('data-todo-id');
}

/**
 * Update visual state of a todo item based on completion status
 * @param {HTMLElement} todoItem - The todo item container element
 * @param {boolean} completed - The new completion status
 */
export function updateItemVisualState(todoItem, completed) {
  const checkbox = todoItem.querySelector('input[type="checkbox"]');
  const textElement = todoItem.querySelector('[data-testid^="todo-item-text-"]');

  // Update checkbox checked state
  if (checkbox) {
    checkbox.checked = completed;
  }

  // Update item class
  if (completed) {
    todoItem.classList.add('todo-completed');
  } else {
    todoItem.classList.remove('todo-completed');
  }

  // Update text styling
  if (textElement) {
    textElement.style.textDecoration = completed ? 'line-through' : 'none';
  }
}

/**
 * Update the active counter display
 * @param {number} count - The new active count
 */
export function updateCounterDisplay(count) {
  const counter = document.querySelector('[data-testid="active-counter-display"]');
  if (counter) {
    const suffix = count === 1 ? 'item' : 'items';
    counter.textContent = `${count} ${suffix} left`;
  }
}

/**
 * Re-render the todo list container with updated todos
 * @param {Array} todos - The updated todos array
 * @param {HTMLElement} container - The list container element
 * @param {Function} renderItem - Function to render individual items
 */
export function rerenderList(container, todos, renderItem) {
  if (!container) return;

  // Clear current content
  container.innerHTML = '';

  // Re-render all items
  todos.forEach(todo => {
    const itemElement = renderItem(todo);
    container.appendChild(itemElement);
  });
}

/**
 * Main toggle handler - processes checkbox change event
 * Extracts todo id, calls store toggle, updates UI
 *
 * @param {HTMLInputElement} checkboxElement - The checkbox that triggered the event
 * @param {Object} store - The todo store with toggleTodo method
 * @param {Function} onComplete - Callback when toggle completes successfully
 * @param {Function} onError - Callback when toggle fails
 * @returns {Object} - Result object { toggled: boolean, id: string|null }
 */
export function handleToggle(checkboxElement, store, onComplete, onError) {
  const id = extractTodoId(checkboxElement);

  if (!id) {
    return { toggled: false, id: null };
  }

  // Find parent item for immediate visual feedback
  const todoItem = checkboxElement.closest('[data-testid^="todo-item-"]');

  try {
    // Call store toggle operation (boundary contract)
    store.toggleTodo(id);

    // Trigger re-render callback
    if (onComplete) {
      onComplete(id);
    }

    return { toggled: true, id };
  } catch (error) {
    // Restore checkbox state on error
    if (todoItem) {
      const checkbox = todoItem.querySelector('input[type="checkbox"]');
      if (checkbox) {
        checkbox.checked = !checkbox.checked;
      }
    }

    if (onError) {
      onError(error);
    }

    return { toggled: false, id, error };
  }
}

/**
 * Attach toggle handler to a todo list container using event delegation
 * @param {HTMLElement} container - The todo list container
 * @param {Object} store - The todo store
 * @param {Function} renderCallback - Callback to trigger full re-render
 */
export function attachToggleHandler(container, store, renderCallback) {
  if (!container) return;

  container.addEventListener('change', (event) => {
    const checkbox = event.target;

    // Only handle checkbox inputs within todo items
    if (checkbox.type === 'checkbox' && checkbox.closest('[data-testid^="todo-item-"]')) {
      const result = handleToggle(
        checkbox,
        store,
        (id) => {
          // On success: update local visual state and trigger re-render
          const todoItem = checkbox.closest('[data-testid^="todo-item-"]');
          if (todoItem) {
            const newCompleted = checkbox.checked;
            updateItemVisualState(todoItem, newCompleted);
          }

          // Trigger full re-render for counter and filter updates
          if (renderCallback) {
            renderCallback();
          }
        },
        (error) => {
          // On error: log and show user feedback
          console.error('Toggle failed:', error);
        }
      );

      // Prevent default if toggle wasn't processed
      if (!result.toggled) {
        event.preventDefault();
      }
    }
  });
}

/**
 * Create a toggle handler bound to specific store and renderer
 * Factory pattern for extensible handler creation
 *
 * @param {Object} deps - Dependencies { store, renderCallback }
 * @returns {Function} - Bound toggle handler function
 */
export function createToggleHandler(deps) {
  const { store, renderCallback } = deps;

  return function(checkboxElement) {
    return handleToggle(checkboxElement, store, renderCallback, (error) => {
      console.error('Toggle operation failed:', error);
    });
  };
}

// Default export for compatibility
export default {
  handleToggle,
  attachToggleHandler,
  createToggleHandler,
  extractTodoId,
  updateItemVisualState,
  updateCounterDisplay,
  rerenderList,
};
