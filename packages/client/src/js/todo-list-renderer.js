/**
 * Todo List Renderer
 * Renders todo items to the DOM with appropriate data-testid attributes
 */

/**
 * Renders a list of todos to the DOM
 * Clears existing content and re-renders the full list
 * @param {Array} todos - Array of todo objects to render
 * @param {Object} options - Optional configuration
 * @param {string} [options.containerSelector='[data-testid="todo-list"]'] - Container selector
 */
export function renderTodoList(todos, options = {}) {
  const containerSelector = options.containerSelector || '[data-testid="todo-list"]';
  const container = document.querySelector(containerSelector);

  if (!container) {
    console.warn(`Todo list container not found: ${containerSelector}`);
    return;
  }

  // Clear existing content
  container.innerHTML = '';

  // Render empty state if no todos
  if (!todos || todos.length === 0) {
    return;
  }

  // Render each todo item
  todos.forEach(todo => {
    const todoEl = createTodoElement(todo);
    container.appendChild(todoEl);
  });
}

/**
 * Creates a DOM element for a single todo item
 * @param {Object} todo - The todo object
 * @param {string} todo.id - Unique identifier
 * @param {string} todo.title - Todo title
 * @param {string} [todo.description] - Optional description
 * @param {string} todo.priority - Priority level (low, medium, high)
 * @param {boolean} todo.completed - Completion status
 * @returns {HTMLElement} The todo item element
 */
function createTodoElement(todo) {
  const todoEl = document.createElement('div');
  todoEl.setAttribute('data-testid', `todo-item-${todo.id}`);
  todoEl.className = `todo-item priority-${todo.priority}`;
  if (todo.completed) {
    todoEl.classList.add('completed');
  }

  // Checkbox for completion toggle
  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.setAttribute('data-testid', `todo-checkbox-${todo.id}`);
  checkbox.checked = todo.completed;
  checkbox.className = 'todo-checkbox';
  todoEl.appendChild(checkbox);

  // Title
  const titleEl = document.createElement('span');
  titleEl.setAttribute('data-testid', `todo-title-${todo.id}`);
  titleEl.className = 'todo-title';
  titleEl.textContent = todo.title;
  todoEl.appendChild(titleEl);

  // Description if present
  if (todo.description) {
    const descEl = document.createElement('div');
    descEl.setAttribute('data-testid', `todo-desc-${todo.id}`);
    descEl.className = 'todo-description';
    descEl.textContent = todo.description;
    todoEl.appendChild(descEl);
  }

  // Delete button
  const deleteBtn = document.createElement('button');
  deleteBtn.setAttribute('data-testid', `todo-delete-btn-${todo.id}`);
  deleteBtn.className = 'todo-delete-btn';
  deleteBtn.textContent = 'Delete';
  todoEl.appendChild(deleteBtn);

  return todoEl;
}

/**
 * Updates a single todo item in the DOM without re-rendering the entire list
 * @param {Object} todo - The updated todo object
 */
export function updateTodoElement(todo) {
  const existingEl = document.querySelector(`[data-testid="todo-item-${todo.id}"]`);

  if (!existingEl) {
    // Element doesn't exist, caller should use full refresh
    return false;
  }

  // Update classes
  existingEl.className = `todo-item priority-${todo.priority}`;
  if (todo.completed) {
    existingEl.classList.add('completed');
  }

  // Update checkbox
  const checkbox = existingEl.querySelector(`[data-testid="todo-checkbox-${todo.id}"]`);
  if (checkbox) {
    checkbox.checked = todo.completed;
  }

  // Update title
  const titleEl = existingEl.querySelector(`[data-testid="todo-title-${todo.id}"]`);
  if (titleEl) {
    titleEl.textContent = todo.title;
  }

  // Update or remove description
  let descEl = existingEl.querySelector(`[data-testid="todo-desc-${todo.id}"]`);
  if (todo.description) {
    if (!descEl) {
      descEl = document.createElement('div');
      descEl.setAttribute('data-testid', `todo-desc-${todo.id}`);
      descEl.className = 'todo-description';
      // Insert after title (which is the second child after checkbox)
      existingEl.insertBefore(descEl, existingEl.children[2]?.nextSibling || null);
    }
    descEl.textContent = todo.description;
  } else if (descEl) {
    descEl.remove();
  }

  return true;
}

/**
 * Removes a todo element from the DOM
 * @param {string} todoId - The id of the todo to remove
 * @returns {boolean} True if element was found and removed
 */
export function removeTodoElement(todoId) {
  const el = document.querySelector(`[data-testid="todo-item-${todoId}"]`);
  if (el) {
    el.remove();
    return true;
  }
  return false;
}
