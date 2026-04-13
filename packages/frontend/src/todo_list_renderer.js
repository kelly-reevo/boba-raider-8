/**
 * Todo list renderer - handles rendering and refreshing the todo list
 */

import { fetchTodos } from './http_client.js';

/**
 * Refresh the todo list display
 * Fetches latest todos and re-renders the list
 */
export async function refresh() {
  const listEl = document.querySelector('[data-testid="todo-list"]');
  if (!listEl) {
    return;
  }

  try {
    const response = await fetchTodos();
    if (!response.ok) {
      throw new Error('Failed to fetch todos');
    }

    const todos = await response.json();
    renderTodos(listEl, todos);
  } catch (error) {
    listEl.innerHTML = `<li data-testid="todo-list-error">Error loading todos: ${error.message}</li>`;
  }
}

/**
 * Render todos into the list element
 * @param {HTMLElement} listEl - The list container element
 * @param {Array} todos - Array of todo objects
 */
function renderTodos(listEl, todos) {
  if (!todos || todos.length === 0) {
    listEl.innerHTML = '<li data-testid="todo-empty">No todos yet</li>';
    return;
  }

  listEl.innerHTML = todos.map(todo => `
    <li data-testid="todo-item" data-todo-id="${todo.id}">
      <span class="todo-title">${escapeHtml(todo.title)}</span>
      <span class="todo-description">${escapeHtml(todo.description || '')}</span>
    </li>
  `).join('');
}

/**
 * Escape HTML to prevent XSS
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
