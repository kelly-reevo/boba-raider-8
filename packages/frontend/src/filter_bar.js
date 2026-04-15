/**
 * Filter Bar Component
 * Handles filter button clicks and updates active state
 */

import { setFilter, getCurrentFilter } from './todo_filter_logic.js';

/**
 * Creates and manages the filter bar UI
 */
export class FilterBar {
  constructor(containerSelector, onFilterChange) {
    this.container = document.querySelector(containerSelector);
    this.onFilterChange = onFilterChange;
    this.buttons = [];
    this.init();
  }

  init() {
    if (!this.container) return;

    this.buttons = this.container.querySelectorAll('[data-testid^="filter-btn-"]');

    this.buttons.forEach(button => {
      button.addEventListener('click', (event) => this.handleFilterClick(event));
    });
  }

  handleFilterClick(event) {
    const button = event.target;
    const filterValue = this.getFilterValueFromButton(button);

    // Update filter state
    setFilter(filterValue);

    // Update UI - remove active from all buttons, add to clicked
    this.updateActiveButton(button);

    // Trigger callback for list re-render
    if (this.onFilterChange) {
      this.onFilterChange(filterValue);
    }
  }

  getFilterValueFromButton(button) {
    const testId = button.getAttribute('data-testid');
    if (testId === 'filter-btn-all') return 'all';
    if (testId === 'filter-btn-active') return 'active';
    if (testId === 'filter-btn-completed') return 'completed';
    return 'all';
  }

  updateActiveButton(activeButton) {
    this.buttons.forEach(btn => {
      btn.classList.remove('active');
    });
    activeButton.classList.add('active');
  }

  setActiveFilter(filterValue) {
    this.buttons.forEach(btn => {
      const btnValue = this.getFilterValueFromButton(btn);
      btn.classList.toggle('active', btnValue === filterValue);
    });
  }
}

/**
 * Initialize filter bar on the given container
 * @param {string} containerSelector - CSS selector for the filter bar container
 * @param {Function} onFilterChange - Callback when filter changes
 * @returns {FilterBar} The initialized filter bar instance
 */
export function initFilterBar(containerSelector, onFilterChange) {
  return new FilterBar(containerSelector, onFilterChange);
}
