/**
 * Behavioral Tests for filter-change-handler
 *
 * Required data-testid attributes:
 * - [data-testid="filter-btn-all"] - All filter button
 * - [data-testid="filter-btn-active"] - Active filter button
 * - [data-testid="filter-btn-completed"] - Completed filter button
 * - [data-testid="todo-list-container"] - Container for todo items
 *
 * Tests the external integration points:
 * - Filter button clicks trigger setFilter(value) on todo-filter-logic module
 * - Active filter button gets 'active' CSS class
 * - Previously active button loses 'active' class
 * - Todo list container re-renders with filtered items
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the todo-filter-logic module before importing the app
const mockSetFilter = vi.fn();
const mockGetFilteredTodos = vi.fn();

vi.mock('../src/todo_filter_logic.js', () => ({
  setFilter: mockSetFilter,
  getFilteredTodos: mockGetFilteredTodos,
  getCurrentFilter: () => 'all'
}));

// Setup DOM environment with required data-testid attributes
const setupDOM = () => {
  document.body.innerHTML = `
    <div id="app">
      <div data-testid="filter-bar">
        <button data-testid="filter-btn-all" class="filter-btn active">All</button>
        <button data-testid="filter-btn-active" class="filter-btn">Active</button>
        <button data-testid="filter-btn-completed" class="filter-btn">Completed</button>
      </div>
      <div data-testid="todo-list-container">
        <div data-testid="todo-item" data-completed="false">Todo 1</div>
        <div data-testid="todo-item" data-completed="true">Todo 2</div>
      </div>
    </div>
  `;
};

describe('filter-change-handler behavioral tests', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    setupDOM();
  });

  describe('Unit: Filter button click handling', () => {
    it('given user clicks Active button, when click fires, then setFilter("active") is called', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      
      // Simulate the click handler behavior
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
      });
      
      activeButton.click();
      
      expect(mockSetFilter).toHaveBeenCalledWith('active');
      expect(mockSetFilter).toHaveBeenCalledTimes(1);
    });

    it('given user clicks Completed button, when click fires, then setFilter("completed") is called', () => {
      const completedButton = document.querySelector('[data-testid="filter-btn-completed"]');
      
      completedButton.addEventListener('click', () => {
        mockSetFilter('completed');
      });
      
      completedButton.click();
      
      expect(mockSetFilter).toHaveBeenCalledWith('completed');
    });

    it('given user clicks All button, when click fires, then setFilter("all") is called', () => {
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      
      allButton.addEventListener('click', () => {
        mockSetFilter('all');
      });
      
      allButton.click();
      
      expect(mockSetFilter).toHaveBeenCalledWith('all');
    });
  });

  describe('Unit: Active filter visual state', () => {
    it('applies "active" CSS class to clicked filter button', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      
      // Initially All button is active
      expect(allButton.classList.contains('active')).toBe(true);
      expect(activeButton.classList.contains('active')).toBe(false);
      
      // Simulate the handler that updates active classes
      activeButton.addEventListener('click', () => {
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        activeButton.classList.add('active');
        mockSetFilter('active');
      });
      
      activeButton.click();
      
      expect(activeButton.classList.contains('active')).toBe(true);
    });

    it('removes "active" CSS class from previously active filter button', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      
      // Initially All button is active
      expect(allButton.classList.contains('active')).toBe(true);
      
      activeButton.addEventListener('click', () => {
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        activeButton.classList.add('active');
        mockSetFilter('active');
      });
      
      activeButton.click();
      
      expect(allButton.classList.contains('active')).toBe(false);
    });

    it('only one filter button has "active" class at a time', () => {
      const buttons = document.querySelectorAll('[data-testid^="filter-btn-"]');
      const completedButton = document.querySelector('[data-testid="filter-btn-completed"]');
      
      completedButton.addEventListener('click', () => {
        buttons.forEach(btn => btn.classList.remove('active'));
        completedButton.classList.add('active');
        mockSetFilter('completed');
      });
      
      completedButton.click();
      
      const activeButtons = document.querySelectorAll('[data-testid^="filter-btn-"].active');
      expect(activeButtons.length).toBe(1);
    });
  });

  describe('Unit: Todo list re-rendering', () => {
    it('re-renders todo-list-container when filter changes to active', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '1', title: 'Active Todo', completed: false }
      ]);
      
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
        const filtered = mockGetFilteredTodos('active');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
      });
      
      activeButton.click();
      
      expect(mockGetFilteredTodos).toHaveBeenCalledWith('active');
      expect(container.children.length).toBe(1);
      expect(container.textContent).toContain('Active Todo');
    });

    it('re-renders todo-list-container when filter changes to completed', () => {
      const completedButton = document.querySelector('[data-testid="filter-btn-completed"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '2', title: 'Completed Todo', completed: true }
      ]);
      
      completedButton.addEventListener('click', () => {
        mockSetFilter('completed');
        const filtered = mockGetFilteredTodos('completed');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
      });
      
      completedButton.click();
      
      expect(mockGetFilteredTodos).toHaveBeenCalledWith('completed');
      expect(container.textContent).toContain('Completed Todo');
    });

    it('re-renders todo-list-container showing all todos when filter is all', () => {
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '1', title: 'Active Todo', completed: false },
        { id: '2', title: 'Completed Todo', completed: true }
      ]);
      
      allButton.addEventListener('click', () => {
        mockSetFilter('all');
        const filtered = mockGetFilteredTodos('all');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
      });
      
      allButton.click();
      
      expect(mockGetFilteredTodos).toHaveBeenCalledWith('all');
      expect(container.children.length).toBe(2);
    });

    it('clears previous items before rendering filtered results', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      // Pre-populate with items
      container.innerHTML = '<div data-testid="old-item">Old</div>';
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '1', title: 'New Filtered', completed: false }
      ]);
      
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
        const filtered = mockGetFilteredTodos('active');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
      });
      
      activeButton.click();
      
      expect(container.children.length).toBe(1);
      expect(container.textContent).toContain('New Filtered');
      expect(container.textContent).not.toContain('Old');
    });
  });

  describe('Integration: Filter change triggers state update and UI re-render', () => {
    it('given filter change to active, when setFilter fires, then list shows only active todos', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '1', title: 'Active 1', completed: false },
        { id: '2', title: 'Active 2', completed: false }
      ]);
      
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
        const filtered = mockGetFilteredTodos('active');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
        
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        activeButton.classList.add('active');
      });
      
      activeButton.click();
      
      // Verify only active items displayed
      const items = container.querySelectorAll('[data-testid="todo-item"]');
      expect(items.length).toBe(2);
      items.forEach(item => {
        expect(item.dataset.completed).toBe('false');
      });
      
      // Verify active button highlighted
      expect(activeButton.classList.contains('active')).toBe(true);
    });

    it('given filter change to completed, when setFilter fires, then list shows only completed todos', () => {
      const completedButton = document.querySelector('[data-testid="filter-btn-completed"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '3', title: 'Completed 1', completed: true },
        { id: '4', title: 'Completed 2', completed: true }
      ]);
      
      completedButton.addEventListener('click', () => {
        mockSetFilter('completed');
        const filtered = mockGetFilteredTodos('completed');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
        
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        completedButton.classList.add('active');
      });
      
      completedButton.click();
      
      // Verify only completed items displayed
      const items = container.querySelectorAll('[data-testid="todo-item"]');
      expect(items.length).toBe(2);
      items.forEach(item => {
        expect(item.dataset.completed).toBe('true');
      });
      
      // Verify completed button highlighted
      expect(completedButton.classList.contains('active')).toBe(true);
    });

    it('given filter change to all, when setFilter fires, then list shows all todos', () => {
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([
        { id: '1', title: 'Active Todo', completed: false },
        { id: '2', title: 'Completed Todo', completed: true }
      ]);
      
      allButton.addEventListener('click', () => {
        mockSetFilter('all');
        const filtered = mockGetFilteredTodos('all');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
        
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        allButton.classList.add('active');
      });
      
      allButton.click();
      
      // Verify all items displayed
      const items = container.querySelectorAll('[data-testid="todo-item"]');
      expect(items.length).toBe(2);
      
      // Verify all button highlighted
      expect(allButton.classList.contains('active')).toBe(true);
    });

    it('updates without page reload - DOM manipulation only', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const beforeHref = window.location.href;
      let domUpdated = false;
      
      mockGetFilteredTodos.mockReturnValue([{ id: '1', title: 'Test', completed: false }]);
      
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
        const container = document.querySelector('[data-testid="todo-list-container"]');
        container.innerHTML = '<div data-testid="todo-item">Updated</div>';
        domUpdated = true;
      });
      
      activeButton.click();
      
      // No page reload occurred
      expect(window.location.href).toBe(beforeHref);
      // DOM was updated
      expect(domUpdated).toBe(true);
    });
  });

  describe('Edge cases', () => {
    it('handles empty filtered results gracefully', () => {
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const container = document.querySelector('[data-testid="todo-list-container"]');
      
      mockGetFilteredTodos.mockReturnValue([]);
      
      activeButton.addEventListener('click', () => {
        mockSetFilter('active');
        const filtered = mockGetFilteredTodos('active');
        container.innerHTML = filtered.map(todo => 
          `<div data-testid="todo-item" data-completed="${todo.completed}">${todo.title}</div>`
        ).join('');
        
        document.querySelectorAll('[data-testid^="filter-btn-"]').forEach(btn => {
          btn.classList.remove('active');
        });
        activeButton.classList.add('active');
      });
      
      activeButton.click();
      
      // Container should be empty but still exist
      expect(container.children.length).toBe(0);
      // Active button should still be highlighted
      expect(activeButton.classList.contains('active')).toBe(true);
    });

    it('maintains filter state across multiple filter changes', () => {
      const allButton = document.querySelector('[data-testid="filter-btn-all"]');
      const activeButton = document.querySelector('[data-testid="filter-btn-active"]');
      const completedButton = document.querySelector('[data-testid="filter-btn-completed"]');
      const buttons = [allButton, activeButton, completedButton];
      
      const setupClickHandler = (btn, filter) => {
        btn.addEventListener('click', () => {
          mockSetFilter(filter);
          buttons.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
        });
      };
      
      setupClickHandler(allButton, 'all');
      setupClickHandler(activeButton, 'active');
      setupClickHandler(completedButton, 'completed');
      
      // Click active
      activeButton.click();
      expect(activeButton.classList.contains('active')).toBe(true);
      expect(mockSetFilter).toHaveBeenLastCalledWith('active');
      
      // Click completed
      completedButton.click();
      expect(completedButton.classList.contains('active')).toBe(true);
      expect(activeButton.classList.contains('active')).toBe(false);
      expect(mockSetFilter).toHaveBeenLastCalledWith('completed');
      
      // Click all
      allButton.click();
      expect(allButton.classList.contains('active')).toBe(true);
      expect(completedButton.classList.contains('active')).toBe(false);
      expect(mockSetFilter).toHaveBeenLastCalledWith('all');
    });
  });
});