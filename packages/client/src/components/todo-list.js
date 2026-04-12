/**
 * Todo List Component - Renders and manages the todo list display
 */

const { fetchTodos } = require('../api/client.js');

/**
 * Render todos to the DOM
 * @param {Array} todos - List of todo objects to render
 */
function renderTodos(todos) {
  const list = document.querySelector('#todo-list');
  if (!list) return;

  list.innerHTML = '';

  if (!todos || todos.length === 0) {
    const emptyItem = document.createElement('li');
    emptyItem.className = 'empty-state';
    emptyItem.textContent = 'No todos yet. Add one above!';
    list.appendChild(emptyItem);
    return;
  }

  todos.forEach(todo => {
    const item = document.createElement('li');
    item.dataset.todoId = todo.id;
    item.className = todo.completed ? 'completed' : '';

    const title = document.createElement('span');
    title.className = 'todo-title';
    title.textContent = todo.title;

    const desc = document.createElement('span');
    desc.className = 'todo-description';
    desc.textContent = todo.description || '';

    const toggleBtn = document.createElement('button');
    toggleBtn.className = 'toggle-btn';
    toggleBtn.textContent = todo.completed ? 'Undo' : 'Complete';

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'delete-btn';
    deleteBtn.textContent = 'Delete';

    item.appendChild(title);
    if (todo.description) {
      item.appendChild(desc);
    }
    item.appendChild(toggleBtn);
    item.appendChild(deleteBtn);

    list.appendChild(item);
  });
}

/**
 * Refresh the todo list from the API
 */
async function refreshTodos() {
  try {
    const todos = await fetchTodos();
    renderTodos(todos);
  } catch (err) {
    console.error('Failed to refresh todos:', err);
  }
}

/**
 * Initialize the todo list component
 */
function initTodoList() {
  refreshTodos();
}

module.exports = {
  renderTodos,
  refreshTodos,
  initTodoList,
};
