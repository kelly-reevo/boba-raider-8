/**
 * Todo list rendering module
 * Renders todo items to the DOM with proper structure and styling classes
 */

/**
 * Render an array of todos into a container element
 * @param {Array} todos - Array of todo objects with id, title, priority, completed, description
 * @param {Document} doc - The DOM document object
 * @param {HTMLElement} listContainer - The container element to render todos into
 */
export function renderTodos(todos, doc, listContainer) {
  // Clear existing items
  listContainer.innerHTML = '';

  todos.forEach(todo => {
    renderTodo(todo, doc, listContainer);
  });
}

/**
 * Render a single todo item into a container
 * @param {Object} todo - Todo object with id, title, priority, completed, description
 * @param {Document} doc - The DOM document object
 * @param {HTMLElement} listContainer - The container element to append the todo to
 * @returns {HTMLElement} The created todo item element
 */
export function renderTodo(todo, doc, listContainer) {
  const item = doc.createElement('div');
  item.className = 'todo-item';
  item.setAttribute('data-id', todo.id);

  const checkbox = doc.createElement('input');
  checkbox.type = 'checkbox';
  checkbox.className = 'toggle-complete';
  checkbox.checked = todo.completed;

  const title = doc.createElement('span');
  title.className = 'title';
  title.textContent = todo.title;

  const priorityBadge = doc.createElement('span');
  priorityBadge.className = `priority-badge priority-${todo.priority}`;
  priorityBadge.textContent = todo.priority;

  const deleteBtn = doc.createElement('button');
  deleteBtn.className = 'delete-btn';
  deleteBtn.textContent = 'Delete';

  item.appendChild(checkbox);
  item.appendChild(title);
  item.appendChild(priorityBadge);

  if (todo.description) {
    const desc = doc.createElement('p');
    desc.className = 'description';
    desc.textContent = todo.description;
    item.appendChild(desc);
  }

  item.appendChild(deleteBtn);
  listContainer.appendChild(item);

  return item;
}
