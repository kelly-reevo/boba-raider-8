/**
 * Filter Change Handler
 * Wires up filter buttons to state management and list re-rendering
 *
 * Boundary Contract Implementation:
 * - Event: filter button click with data-testid attribute (filter-btn-all, filter-btn-active, filter-btn-completed)
 * - Action: setFilter(value), re-render filter-bar (update active classes), re-render todo-list-container with new filter applied
 */

import { setFilter, getFilteredTodos } from './todo_filter_logic.js';

/**
 * Initialize the filter change handler
 * Sets up click event listeners on filter buttons
 * @param {Object} config - Configuration object
 * @param {string} config.filterBarSelector - Selector for filter bar container (default: '[data-testid="filter-bar"]')
 * @param {string} config.listContainerSelector - Selector for todo list container (default: '[data-testid="todo-list-container"]')
 * @param {Function} config.renderItemFn - Function to render a single todo item (default: built-in)
 * @returns {Object} Handler API with init and destroy methods
 */
export function initFilterChangeHandler(config = {}) {
  const filterBarSelector = config.filterBarSelector || '[data-testid="filter-bar"]';
  const listContainerSelector = config.listContainerSelector || '[data-testid="todo-list-container"]';

  const filterBar = document.querySelector(filterBarSelector);
  const listContainer = document.querySelector(listContainerSelector);

  if (!filterBar) {
    console.error('Filter bar not found:', filterBarSelector);
    return null;
  }

  // Get all filter buttons
  const filterButtons = filterBar.querySelectorAll('[data-testid^="filter-btn-"]');

  /**
   * Extract filter value from button's data-testid
   * @param {HTMLElement} button - The filter button element
   * @returns {string} Filter value ('all', 'active', 'completed')
   */
  function getFilterValueFromButton(button) {
    const testId = button.getAttribute('data-testid');
    if (testId === 'filter-btn-all') return 'all';
    if (testId === 'filter-btn-active') return 'active';
    if (testId === 'filter-btn-completed') return 'completed';
    return 'all';
  }

  /**
   * Update active class on filter buttons
   * Removes 'active' from all buttons, adds to the clicked one
   * @param {HTMLElement} activeButton - The button to activate
   */
  function updateFilterBarActiveState(activeButton) {
    filterButtons.forEach(btn => {
      btn.classList.remove('active');
    });
    activeButton.classList.add('active');
  }

  /**
   * Default render function for todo items
   * @param {Object} todo - Todo item with id, title, completed properties
   * @returns {string} HTML string for the todo item
   */
  function defaultRenderItem(todo) {
    return `<div data-testid="todo-item" data-completed="${todo.completed}" data-id="${todo.id}">${todo.title}</div>`;
  }

  const renderItemFn = config.renderItemFn || defaultRenderItem;

  /**
   * Re-render the todo list container with filtered items
   * @param {Array} allTodos - Complete list of todo items
   */
  function renderTodoListContainer(allTodos) {
    if (!listContainer) return;

    const filteredTodos = getFilteredTodos(allTodos);

    // Clear previous items
    listContainer.innerHTML = '';

    // Render filtered results
    filteredTodos.forEach(todo => {
      listContainer.innerHTML += renderItemFn(todo);
    });
  }

  /**
   * Handle filter button click
   * 1. Call setFilter with the filter value
   * 2. Update filter bar active classes
   * 3. Re-render todo list container with filtered items
   * @param {Event} event - Click event
   */
  function handleFilterClick(event) {
    const button = event.target;
    const filterValue = getFilterValueFromButton(button);

    // 1. Set the filter value in state
    setFilter(filterValue);

    // 2. Re-render filter bar (update active classes)
    updateFilterBarActiveState(button);

    // 3. Re-render todo list container (if todos are provided in config)
    if (config.todos) {
      renderTodoListContainer(config.todos);
    }

    // Emit event for external handlers
    if (config.onFilterChange) {
      config.onFilterChange(filterValue);
    }
  }

  // Attach click listeners to all filter buttons
  filterButtons.forEach(button => {
    button.addEventListener('click', handleFilterClick);
  });

  // Public API
  return {
    /**
     * Manually trigger a filter change
     * @param {string} filterValue - 'all', 'active', or 'completed'
     */
    setFilter(filterValue) {
      setFilter(filterValue);

      // Update button state
      filterButtons.forEach(btn => {
        const btnValue = getFilterValueFromButton(btn);
        btn.classList.toggle('active', btnValue === filterValue);
      });

      // Re-render list if todos available
      if (config.todos) {
        renderTodoListContainer(config.todos);
      }

      if (config.onFilterChange) {
        config.onFilterChange(filterValue);
      }
    },

    /**
     * Update the todo list and re-render
     * @param {Array} todos - New array of todo items
     */
    updateTodos(todos) {
      config.todos = todos;
      renderTodoListContainer(todos);
    },

    /**
     * Destroy the handler and clean up event listeners
     */
    destroy() {
      filterButtons.forEach(button => {
        button.removeEventListener('click', handleFilterClick);
      });
    }
  };
}
