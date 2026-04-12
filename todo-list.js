/**
 * Todo list rendering and refresh functionality
 */

const API_BASE_URL = '/api';

/**
 * Fetches and refreshes the todo list display
 * Clears and repopulates the #todo-list element
 */
export async function refreshTodoList() {
  const todoList = document.getElementById('todo-list');
  if (!todoList) return;

  try {
    const response = await fetch(`${API_BASE_URL}/todos`);
    const todos = await response.json();

    // Clear existing items
    todoList.innerHTML = '';

    // Render todos
    todos.forEach(todo => {
      const li = document.createElement('li');
      li.className = todo.completed ? 'completed' : '';
      li.innerHTML = `
        <span class="todo-title">${escapeHtml(todo.title)}</span>
        ${todo.description ? `<span class="todo-description">${escapeHtml(todo.description)}</span>` : ''}
      `;
      todoList.appendChild(li);
    });

    // Show empty state if no todos
    if (todos.length === 0) {
      const emptyMsg = document.createElement('li');
      emptyMsg.className = 'empty-message';
      emptyMsg.textContent = 'No todos yet. Add one above!';
      todoList.appendChild(emptyMsg);
    }
  } catch (error) {
    todoList.innerHTML = '<li class="error-message">Failed to load todos</li>';
  }
}

/**
 * Escapes HTML to prevent XSS
 */
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
