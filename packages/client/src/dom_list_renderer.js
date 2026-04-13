/**
 * DOM List Renderer - Renders todo list to DOM
 *
 * Boundary contracts:
 * - renderTodos(todos: Todo[]) -> void (mutates DOM element with id 'todo-list')
 * - Each item: <li class='todo-item priority-{p}' data-id='{id}'>
 *   - Checkbox with class 'todo-toggle', data-id='{id}'
 *   - Title span with class 'todo-title'
 *   - Description div with class 'todo-description' (if present)
 *   - Delete button with class 'todo-delete-btn', data-id='{id}'
 */

/**
 * Renders an array of todos to the DOM element with id 'todo-list'
 * Hides loading state and shows todo list when called.
 * @param {Array<{id: string, title: string, description: string|null, priority: string, completed: boolean}>} todos
 * @returns {void}
 * @throws {Error} If DOM element with id 'todo-list' is not found
 */
export function renderTodos(todos) {
  const container = document.getElementById('todo-list');
  if (!container) {
    throw new Error('Required DOM element #todo-list not found');
  }

  // Hide loading state and show todo list
  const loadingState = document.getElementById('loading-state');
  const errorState = document.getElementById('error-state');

  if (loadingState) {
    loadingState.style.display = 'none';
  }
  if (errorState) {
    errorState.style.display = 'none';
  }
  container.style.display = 'block';

  container.innerHTML = '';

  todos.forEach(todo => {
    const todoEl = createTodoElement(todo);
    container.appendChild(todoEl);
  });
}

/**
 * Creates a DOM element for a single todo item
 * @param {Object} todo
 * @returns {HTMLElement}
 */
function createTodoElement(todo) {
  const todoEl = document.createElement('li');
  todoEl.className = `todo-item priority-${todo.priority}`;
  todoEl.setAttribute('data-id', todo.id);

  if (todo.completed) {
    todoEl.classList.add('completed');
  }

  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.className = 'todo-toggle';
  checkbox.checked = todo.completed;
  checkbox.setAttribute('data-id', todo.id);
  todoEl.appendChild(checkbox);

  const titleEl = document.createElement('span');
  titleEl.className = 'todo-title';
  titleEl.textContent = todo.title;
  todoEl.appendChild(titleEl);

  if (todo.description && todo.description.trim() !== '') {
    const descEl = document.createElement('div');
    descEl.className = 'todo-description';
    descEl.textContent = todo.description;
    todoEl.appendChild(descEl);
  }

  const deleteBtn = document.createElement('button');
  deleteBtn.className = 'todo-delete-btn';
  deleteBtn.setAttribute('data-id', todo.id);
  deleteBtn.textContent = 'Delete';
  todoEl.appendChild(deleteBtn);

  return todoEl;
}

/**
 * Shows error state in the UI
 * Hides loading state and todo list, shows error message.
 * @param {string} [errorMessage] - Optional custom error message
 * @returns {void}
 */
export function showErrorState(errorMessage) {
  const loadingState = document.getElementById('loading-state');
  const todoList = document.getElementById('todo-list');
  const errorState = document.getElementById('error-state');

  if (loadingState) {
    loadingState.style.display = 'none';
  }
  if (todoList) {
    todoList.style.display = 'none';
  }
  if (errorState) {
    errorState.style.display = 'block';
    errorState.textContent = errorMessage || 'Failed to load todos. Please try again.';
  }
}
