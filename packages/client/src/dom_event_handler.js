// DOM Event Handler for todo interactions (toggle, delete)
// Uses event delegation on #todo-list container

import { updateTodo, deleteTodo } from './api.js';
import { renderTodos } from './dom_list_renderer.js';

// Pending request tracking for race condition prevention
const pendingRequests = new Map();

/**
 * Initialize event handlers for todo list interactions
 * Sets up event delegation on #todo-list container
 */
export function initEventHandlers() {
  const todoList = document.getElementById('todo-list');
  if (!todoList) {
    return;
  }

  // Remove existing listener to prevent duplicates
  todoList.removeEventListener('change', handleChange);
  todoList.addEventListener('change', handleChange);

  todoList.removeEventListener('click', handleClick);
  todoList.addEventListener('click', handleClick);
}

/**
 * Handle change events (checkbox toggles)
 * @param {Event} event
 */
async function handleChange(event) {
  const target = event.target;

  // Only handle toggle checkbox changes
  if (!target.classList.contains('todo-toggle')) {
    return;
  }

  const todoId = target.getAttribute('data-id');
  const todoItem = target.closest('.todo-item');
  const completed = target.checked;
  const statusMessage = document.getElementById('status-message');

  if (!todoId || !todoItem) {
    return;
  }

  // Clear any previous status message
  if (statusMessage) {
    statusMessage.textContent = '';
  }

  // Cancel any pending request for this todo
  if (pendingRequests.has(todoId)) {
    pendingRequests.delete(todoId);
  }

  // Optimistically update UI
  todoItem.classList.toggle('completed', completed);

  try {
    // Track this request
    const requestKey = `${todoId}-toggle`;
    pendingRequests.set(requestKey, Date.now());

    await updateTodo(todoId, { completed });

    // Remove from pending
    pendingRequests.delete(requestKey);
  } catch (error) {
    // Remove from pending
    pendingRequests.delete(`${todoId}-toggle`);

    // Revert checkbox on error
    target.checked = !completed;
    todoItem.classList.toggle('completed', !completed);

    // Display error
    if (statusMessage) {
      statusMessage.textContent = 'Error updating todo';
    }
  }
}

/**
 * Handle click events (delete buttons)
 * @param {Event} event
 */
async function handleClick(event) {
  const target = event.target;

  // Only handle delete button clicks
  if (!target.classList.contains('todo-delete-btn') &&
      !target.classList.contains('todo-delete')) {
    return;
  }

  const todoId = target.getAttribute('data-id') ||
                 target.closest('.todo-item')?.getAttribute('data-id');
  const todoItem = target.closest('.todo-item');
  const statusMessage = document.getElementById('status-message');

  if (!todoId || !todoItem) {
    return;
  }

  // Clear any previous status message
  if (statusMessage) {
    statusMessage.textContent = '';
  }

  // Add deleting class for animation
  todoItem.classList.add('deleting');

  try {
    await deleteTodo(todoId);

    // Wait for animation then remove
    setTimeout(() => {
      todoItem.remove();
    }, 300);
  } catch (error) {
    // Remove deleting class on error
    todoItem.classList.remove('deleting');

    // Display error
    if (statusMessage) {
      statusMessage.textContent = 'Error deleting todo';
    }
  }
}

/**
 * Refresh the todo list by fetching and re-rendering
 */
export async function refreshTodoList() {
  try {
    const { fetchTodos } = await import('./api.js');
    const todos = await fetchTodos();
    renderTodos(todos);
  } catch (error) {
    const statusMessage = document.getElementById('status-message');
    if (statusMessage) {
      statusMessage.textContent = 'Error loading todos';
    }
    console.error('Failed to refresh list:', error);
  }
}
