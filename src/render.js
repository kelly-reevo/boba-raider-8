import { initDeleteHandlers } from './delete_handler.js';

/**
 * Render the todo list
 * @param {Array} todos - Array of todo items
 */
export function renderList(todos) {
  const container = document.querySelector('[data-testid="todo-list-container"]');
  if (!container) return;

  // Clear current content
  container.innerHTML = '';

  // Check if empty
  if (todos.length === 0) {
    // Show empty state display
    const emptyState = document.querySelector('[data-testid="empty-state-display"]');
    if (emptyState) {
      emptyState.style.display = 'block';
    }
  } else {
    // Hide empty state display
    const emptyState = document.querySelector('[data-testid="empty-state-display"]');
    if (emptyState) {
      emptyState.style.display = 'none';
    }

    // Render each todo item
    todos.forEach(todo => {
      const todoElement = createTodoElement(todo);
      container.appendChild(todoElement);
    });

    // Re-bind delete handlers to new buttons
    initDeleteHandlers();
  }
}

/**
 * Create a single todo DOM element
 * @param {Object} todo
 * @returns {HTMLElement}
 */
function createTodoElement(todo) {
  const div = document.createElement('div');
  div.setAttribute('data-testid', `todo-item-${todo.id}`);
  div.setAttribute('data-id', todo.id);

  // Todo title with completed styling
  const title = document.createElement('span');
  title.setAttribute('data-testid', 'todo-title');
  title.textContent = todo.title;

  if (todo.completed) {
    title.classList.add('completed');
    title.style.textDecoration = 'line-through';
  }

  // Delete button
  const deleteBtn = document.createElement('button');
  deleteBtn.setAttribute('data-testid', `delete-btn-${todo.id}`);
  deleteBtn.setAttribute('data-id', todo.id);
  deleteBtn.textContent = 'Delete';

  div.appendChild(title);
  div.appendChild(deleteBtn);

  return div;
}

/**
 * Render the active counter display
 * @param {number} count - Number of active items
 */
export function renderCounter(count) {
  const counter = document.querySelector('[data-testid="active-counter-display"]');
  if (!counter) return;

  const itemText = count === 1 ? 'item' : 'items';
  counter.textContent = `${count} ${itemText} left`;
}
