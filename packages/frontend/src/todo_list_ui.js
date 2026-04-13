/**
 * Todo List UI Module
 * Handles delete button interactions with event delegation
 * Manages delete confirmation, API calls, and DOM updates
 */

import { deleteTodo, getAllTodos } from './api_client.js';
import {
  getByTestId,
  removeTodoElement,
  showEmptyState,
  showErrorMessage,
  hideErrorMessage,
  extractTodoId,
} from './dom_utils.js';

// Configuration for confirmation dialog
const CONFIRM_DELETE_MESSAGE = 'Are you sure you want to delete this todo?';

/**
 * Initialize the todo list UI with event delegation
 * Attaches click handler to the todo-list container for delete button clicks
 */
export function initTodoListUI() {
  const todoList = getByTestId('todo-list');
  if (!todoList) {
    console.error('Todo list container not found');
    return;
  }

  // Attach event delegation handler
  todoList.addEventListener('click', handleTodoListClick);

  // Attach error refresh button handler if present
  const errorRefreshBtn = getByTestId('error-refresh-btn');
  if (errorRefreshBtn) {
    errorRefreshBtn.addEventListener('click', handleRefreshClick);
  }
}

/**
 * Handle click events on the todo list container
 * Uses event delegation to handle delete button clicks
 * @param {MouseEvent} event - The click event
 */
function handleTodoListClick(event) {
  const target = event.target;

  // Check if clicked element is a delete button
  if (target.getAttribute('data-testid') === 'delete-todo-btn') {
    handleDeleteClick(target);
  }
}

/**
 * Handle delete button click
 * Shows confirmation dialog, calls API, updates DOM on success
 * @param {Element} deleteBtn - The delete button element
 */
async function handleDeleteClick(deleteBtn) {
  // Show confirmation dialog
  const shouldDelete = confirm(CONFIRM_DELETE_MESSAGE);
  if (!shouldDelete) {
    return; // User cancelled, do nothing
  }

  // Extract todo ID from parent element
  const todoId = extractTodoId(deleteBtn);
  if (!todoId) {
    console.error('Could not extract todo ID from delete button');
    return;
  }

  // Hide any previous error messages
  hideErrorMessage();

  try {
    // Call API to delete the todo
    await deleteTodo(todoId);

    // On success, remove the element from DOM
    removeTodoElement(todoId);

    // Check if empty state should be shown
    showEmptyState();

  } catch (error) {
    // Handle different error types
    if (error.status === 404) {
      showErrorMessage('Todo not found. It may have already been deleted.');
    } else if (error.status >= 500) {
      showErrorMessage('Failed to delete todo. Please try again.');
    } else if (error.message && error.message.includes('Network')) {
      showErrorMessage('Network error. Please check your connection.');
    } else {
      showErrorMessage('Failed to delete todo. Please try again.');
    }

    // Refresh list to sync with server state
    await refreshList();
  }
}

/**
 * Handle refresh button click
 * Re-fetches the todo list from the server
 */
async function handleRefreshClick() {
  hideErrorMessage();
  await refreshList();
}

/**
 * Refresh the todo list by re-fetching from the API
 * Re-renders the entire list to ensure sync with server state
 */
export async function refreshList() {
  try {
    const todos = await getAllTodos();
    renderTodoList(todos);
  } catch (error) {
    showErrorMessage('Failed to refresh todo list. Please try again.');
  }
}

/**
 * Render the todo list with the given todos
 * @param {Array} todos - Array of todo objects to render
 */
function renderTodoList(todos) {
  const todoList = getByTestId('todo-list');
  const emptyState = getByTestId('empty-state');

  if (!todoList) return;

  // Clear existing items
  todoList.innerHTML = '';

  if (!todos || todos.length === 0) {
    // Show empty state
    if (emptyState) {
      emptyState.classList.remove('hidden');
      emptyState.style.display = 'flex';
    }
    return;
  }

  // Hide empty state
  if (emptyState) {
    emptyState.classList.add('hidden');
    emptyState.style.display = 'none';
  }

  // Render each todo item
  for (const todo of todos) {
    const todoElement = createTodoElement(todo);
    todoList.appendChild(todoElement);
  }
}

/**
 * Create a DOM element for a todo item
 * @param {Object} todo - The todo object
 * @param {string} todo.id - The todo ID
 * @param {string} todo.title - The todo title
 * @param {boolean} todo.completed - Whether the todo is completed
 * @returns {HTMLElement} The created todo element
 */
function createTodoElement(todo) {
  const div = document.createElement('div');
  div.setAttribute('data-todo-id', todo.id);
  div.setAttribute('data-testid', `todo-item-${todo.id}`);
  div.className = 'todo-item';

  // Todo content
  const content = document.createElement('span');
  content.textContent = todo.title;
  content.className = todo.completed ? 'todo-title completed' : 'todo-title';

  // Delete button
  const deleteBtn = document.createElement('button');
  deleteBtn.setAttribute('data-testid', 'delete-todo-btn');
  deleteBtn.textContent = 'Delete';
  deleteBtn.className = 'delete-btn';

  div.appendChild(content);
  div.appendChild(deleteBtn);

  return div;
}

/**
 * Clean up event listeners when needed
 * Useful for testing or hot module replacement
 */
export function cleanupTodoListUI() {
  const todoList = getByTestId('todo-list');
  if (todoList) {
    todoList.removeEventListener('click', handleTodoListClick);
  }

  const errorRefreshBtn = getByTestId('error-refresh-btn');
  if (errorRefreshBtn) {
    errorRefreshBtn.removeEventListener('click', handleRefreshClick);
  }
}
