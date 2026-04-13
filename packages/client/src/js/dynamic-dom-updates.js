/**
 * Dynamic DOM Updates
 * Core mechanism for updating the DOM without page reload
 * After any CRUD operation, re-fetches and re-renders the affected portion of the UI
 */

import { listTodos } from './http-client-api.js';
import { renderTodoList } from './todo-list-renderer.js';

// Current filter state - maintained across refreshes
let currentFilter = 'all';

// Track if a refresh is in progress to prevent race conditions
let isRefreshing = false;

/**
 * Boundary contract: refreshList()
 * Calls listTodos(currentFilter), then renderTodoList(result)
 * Re-fetches and re-renders the todo list without page reload
 *
 * @param {string} [filter] - Optional filter to apply ('all', 'active', 'completed')
 *                            If not provided, uses the current filter state
 * @param {Function} [listTodosFn] - Optional listTodos function for dependency injection (testing)
 * @param {Function} [renderTodoListFn] - Optional renderTodoList function for dependency injection (testing)
 * @returns {Promise<void>}
 * @throws {Error} When listTodos fails - error propagates to caller
 */
export async function refreshList(filter, listTodosFn, renderTodoListFn) {
  // Use provided filter or fall back to current filter state
  const filterToUse = filter !== undefined ? filter : currentFilter;

  // Update current filter state
  currentFilter = filterToUse;

  // Use provided functions or default implementations
  const listFn = listTodosFn || listTodos;
  const renderFn = renderTodoListFn || renderTodoList;

  // Call listTodos with current filter and await result
  const result = await listFn(filterToUse);

  // Render the result to the DOM
  renderFn(result);
}

/**
 * Sets the current filter without triggering a refresh
 * @param {string} filter - The filter to set ('all', 'active', 'completed')
 */
export function setFilter(filter) {
  currentFilter = filter;
}

/**
 * Gets the current filter
 * @returns {string} The current filter value
 */
export function getFilter() {
  return currentFilter;
}

/**
 * Refresh the todo list after a create operation
 * @param {string} [filter] - Optional filter override
 * @returns {Promise<void>}
 */
export async function refreshAfterCreate(filter) {
  await refreshList(filter);
}

/**
 * Refresh the todo list after a delete operation
 * @param {string} [filter] - Optional filter override
 * @returns {Promise<void>}
 */
export async function refreshAfterDelete(filter) {
  await refreshList(filter);
}

/**
 * Refresh the todo list after an update operation
 * @param {string} [filter] - Optional filter override
 * @returns {Promise<void>}
 */
export async function refreshAfterUpdate(filter) {
  await refreshList(filter);
}

/**
 * Initialize dynamic DOM updates
 * Sets up event listeners for form submissions and button clicks
 * @param {Object} options - Configuration options
 * @param {Function} [options.onRefresh] - Callback after successful refresh
 * @param {Function} [options.onError] - Callback when refresh fails
 */
export function initDynamicDOMUpdates(options = {}) {
  const { onRefresh, onError } = options;

  // Listen for form submissions (create operations)
  document.addEventListener('submit', async (event) => {
    const form = event.target;
    if (form.matches('[data-testid="todo-form"]')) {
      event.preventDefault();

      try {
        await refreshAfterCreate();
        if (onRefresh) onRefresh();
      } catch (error) {
        if (onError) onError(error);
      }
    }
  });

  // Listen for delete button clicks
  document.addEventListener('click', async (event) => {
    const deleteBtn = event.target.closest('[data-testid^="todo-delete-btn-"]');
    if (deleteBtn) {
      try {
        await refreshAfterDelete();
        if (onRefresh) onRefresh();
      } catch (error) {
        if (onError) onError(error);
      }
    }
  });

  // Listen for checkbox toggles (update operations)
  document.addEventListener('change', async (event) => {
    const checkbox = event.target.closest('[data-testid^="todo-checkbox-"]');
    if (checkbox) {
      try {
        await refreshAfterUpdate();
        if (onRefresh) onRefresh();
      } catch (error) {
        if (onError) onError(error);
      }
    }
  });
}
