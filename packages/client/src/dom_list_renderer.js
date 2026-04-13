/**
 * DOM List Renderer - Renders todo list to DOM
 *
 * Boundary contracts:
 * - renderTodos(todos: Todo[]) -> void (mutates DOM element with id 'todo-list')
 * - Each item: <div class='todo-item priority-{p}' data-id='{id}'>
 *   - Checkbox with class 'todo-checkbox', data-action='toggle'
 *   - Title span with class 'todo-title'
 *   - Description div with class 'todo-description' (if present)
 *   - Delete button with class 'todo-delete', data-action='delete'
 */

/**
 * Renders an array of todos to the DOM element with id 'todo-list'
 * @param {Array<{id: string, title: string, description: string|null, priority: string, completed: boolean}>} todos
 * @returns {void}
 * @throws {Error} If DOM element with id 'todo-list' is not found
 */
export function renderTodos(todos) {
  const container = document.getElementById('todo-list');
  if (!container) {
    throw new Error('Required DOM element #todo-list not found');
  }

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
  const todoEl = document.createElement('div');
  todoEl.className = `todo-item priority-${todo.priority}`;
  todoEl.setAttribute('data-id', todo.id);

  if (todo.completed) {
    todoEl.classList.add('completed');
  }

  const checkbox = document.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.className = 'todo-checkbox';
  checkbox.checked = todo.completed;
  checkbox.setAttribute('data-action', 'toggle');
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
  deleteBtn.className = 'todo-delete';
  deleteBtn.setAttribute('data-action', 'delete');
  deleteBtn.textContent = 'Delete';
  todoEl.appendChild(deleteBtn);

  return todoEl;
}
