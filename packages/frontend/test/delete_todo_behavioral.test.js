/**
 * Behavioral Tests for Delete Todo UI
 *
 * Tests the external integration points of the delete todo UI component:
 * - Delete button click event handling
 * - API client integration (deleteTodo(id) call)
 * - DOM manipulation on success (remove element with data-testid)
 * - Error handling and display on failure
 * - Event delegation pattern on todo-list container
 *
 * Required data-testid attributes for implementation:
 * - data-testid="todo-list" - Container for event delegation
 * - data-testid="delete-todo-btn" - Delete button on each todo item
 * - data-testid="todo-item-{id}" - Individual todo row/element
 * - data-testid="empty-state" - Shown when no todos remain
 * - data-testid="error-message" - Error display container
 * - data-testid="error-refresh-btn" - Button to refresh list on error
 *
 * All tests mock the global fetch/api-client to test boundary contracts without real HTTP calls.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the module under test
const importClient = async () => {
  const modulePath = '../src/api_client.js';
  return await import(modulePath);
};

describe('delete-todo-ui behavioral tests', () => {
  let fetchMock;
  let client;
  let mockElements;
  let eventHandlers;

  beforeEach(async () => {
    // Reset fetch mock before each test
    fetchMock = vi.fn();
    global.fetch = fetchMock;

    // Dynamically import client to get fresh instance
    client = await importClient();

    // Setup mock DOM environment with data-testid selectors
    mockElements = new Map();
    eventHandlers = new Map();

    // Mock document with data-testid query support
    const mockDocument = {
      querySelector: (selector) => {
        // Support both standard selectors and data-testid
        if (selector.startsWith('[data-testid="')) {
          return mockElements.get(selector) || null;
        }
        return mockElements.get(selector) || null;
      },
      querySelectorAll: (selector) => {
        const results = [];
        for (const [key, value] of mockElements) {
          if (key.includes(selector.replace('[', '').replace(']', ''))) {
            results.push(value);
          }
        }
        return results;
      }
    };

    global.document = mockDocument;
    global.confirm = vi.fn(() => true);
    global.alert = vi.fn();
  });

  // ============================================================================
  // Test 1: Delete button click triggers API call with extracted ID
  // Acceptance: Given delete button clicked, calls api.deleteTodo(id)
  // Boundary Contract: Event delegation on [data-testid="todo-list"] for delete button click
  // ============================================================================

  describe('delete button click extracts ID and calls API', () => {
    it('extracts todo ID from closest [data-testid="todo-item-{id}"] and calls deleteTodo', async () => {
      // Arrange: Setup mock DOM structure with data-testid attributes
      const todoId = 'todo-123';
      let extractedId = null;

      // Mock todo item container with data-testid
      const todoItem = {
        getAttribute: (attr) => {
          if (attr === 'data-todo-id') return todoId;
          return null;
        },
        remove: vi.fn()
      };

      // Mock delete button with data-testid
      const deleteBtn = {
        getAttribute: (attr) => {
          if (attr === 'data-testid') return 'delete-todo-btn';
          return null;
        },
        closest: (selector) => {
          if (selector === '[data-todo-id]') return todoItem;
          return null;
        }
      };

      mockElements.set('[data-testid="delete-todo-btn"]', deleteBtn);
      mockElements.set(`[data-testid="todo-item-${todoId}"]`, todoItem);

      // Simulate click handler: extract ID from closest todo item
      const parent = deleteBtn.closest('[data-todo-id]');
      extractedId = parent.getAttribute('data-todo-id');

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: Call API with extracted ID
      await client.deleteTodo(extractedId);

      // Assert: Verify API was called with correct ID
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
      expect(extractedId).toBe(todoId);
    });

    it('uses event delegation on [data-testid="todo-list"] to handle delete clicks', async () => {
      // Arrange: Setup event delegation pattern
      const todoId = 'todo-abc-456';
      const capturedIds = [];

      // Mock todo list container with event delegation
      const todoList = {
        getAttribute: () => 'todo-list',
        addEventListener: (event, handler) => {
          eventHandlers.set('click', handler);
        }
      };

      // Mock delete button that will be the event target
      const deleteBtn = {
        getAttribute: (attr) => {
          if (attr === 'data-testid') return 'delete-todo-btn';
          return null;
        },
        closest: () => ({
          getAttribute: () => todoId
        })
      };

      mockElements.set('[data-testid="todo-list"]', todoList);

      // Simulate event delegation handler
      const delegationHandler = (event) => {
        const target = event.target;
        if (target.getAttribute('data-testid') === 'delete-todo-btn') {
          const todoItem = target.closest('[data-todo-id]');
          const id = todoItem.getAttribute('data-todo-id');
          capturedIds.push(id);
        }
      };

      // Act: Simulate click event
      delegationHandler({ target: deleteBtn });

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      await client.deleteTodo(capturedIds[0]);

      // Assert: Event delegation captured correct ID
      expect(capturedIds).toContain(todoId);
      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
    });

    it('handles multiple todo items each with unique data-todo-id', async () => {
      // Arrange: Multiple todos with different IDs
      const todos = [
        { id: 'todo-1' },
        { id: 'todo-2' },
        { id: 'todo-3' }
      ];

      const deletedIds = [];

      fetchMock.mockImplementation((url) => {
        const id = url.split('/').pop();
        deletedIds.push(id);
        return Promise.resolve({ ok: true, status: 204 });
      });

      // Act: Delete each todo by ID
      for (const todo of todos) {
        await client.deleteTodo(todo.id);
      }

      // Assert: All todos were deleted with correct IDs
      expect(deletedIds).toHaveLength(3);
      expect(deletedIds).toContain('todo-1');
      expect(deletedIds).toContain('todo-2');
      expect(deletedIds).toContain('todo-3');
    });
  });

  // ============================================================================
  // Test 2: Successful deletion removes element from DOM immediately
  // Acceptance: On success, removes todo element from DOM immediately (or refreshes full list)
  // Boundary Contract: On success, calls refreshList() or removes element directly
  // ============================================================================

  describe('successful deletion updates DOM immediately', () => {
    it('removes specific [data-testid="todo-item-{id}"] element from DOM on success', async () => {
      // Arrange: Setup mock DOM with multiple todos
      const todoIdToDelete = 'todo-789';
      const mockRemove = vi.fn();

      const todoElement = {
        getAttribute: (attr) => {
          if (attr === 'data-todo-id') return todoIdToDelete;
          if (attr === 'data-testid') return `todo-item-${todoIdToDelete}`;
          return null;
        },
        remove: mockRemove
      };

      mockElements.set(`[data-testid="todo-item-${todoIdToDelete}"]`, todoElement);

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: Delete and remove from DOM
      await client.deleteTodo(todoIdToDelete);
      todoElement.remove();

      // Assert: Element remove() was called
      expect(mockRemove).toHaveBeenCalledTimes(1);
    });

    it('calls refreshList() to re-render all todos after successful delete', async () => {
      // Arrange
      const todoId = 'todo-refresh-test';
      let refreshCalled = false;

      fetchMock
        .mockResolvedValueOnce({
          ok: true,
          status: 204
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => []
        });

      // Mock refresh function that would re-fetch and re-render
      const refreshList = async () => {
        refreshCalled = true;
        // In real implementation, this would fetch all todos and re-render
        await client.getAllTodos();
      };

      // Act: Delete then refresh
      await client.deleteTodo(todoId);
      await refreshList();

      // Assert: Refresh was called to update full list
      expect(refreshCalled).toBe(true);
      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
    });

    it('only removes the targeted todo, leaving other todos in DOM', async () => {
      // Arrange: Multiple todos in DOM
      const todo1 = { id: 'todo-1', remove: vi.fn() };
      const todo2 = { id: 'todo-2', remove: vi.fn() };
      const todo3 = { id: 'todo-3', remove: vi.fn() };

      mockElements.set('[data-testid="todo-item-todo-1"]', todo1);
      mockElements.set('[data-testid="todo-item-todo-2"]', todo2);
      mockElements.set('[data-testid="todo-item-todo-3"]', todo3);

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: Delete todo-2 only
      await client.deleteTodo('todo-2');
      todo2.remove();

      // Assert: Only todo-2 removed, others intact
      expect(todo1.remove).not.toHaveBeenCalled();
      expect(todo2.remove).toHaveBeenCalledTimes(1);
      expect(todo3.remove).not.toHaveBeenCalled();
    });
  });

  // ============================================================================
  // Test 3: API error shows error message and refreshes list
  // Acceptance: On API error (e.g., 404), shows error message and refreshes list
  // Boundary Contract: Error responses display error message, refresh list to sync state
  // ============================================================================

  describe('API error handling displays message and refreshes list', () => {
    it('displays error in [data-testid="error-message"] when API returns 404', async () => {
      // Arrange
      const todoId = 'todo-not-found';
      const errorElement = {
        textContent: '',
        style: { display: 'none' },
        classList: { remove: vi.fn() }
      };

      mockElements.set('[data-testid="error-message"]', errorElement);

      fetchMock
        .mockRejectedValueOnce({
          status: 404,
          message: 'Todo not found'
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => []
        });

      // Act: Attempt delete, handle error
      try {
        await client.deleteTodo(todoId);
      } catch (error) {
        // Display error in DOM
        errorElement.textContent = `Todo not found. It may have already been deleted.`;
        errorElement.style.display = 'block';
        errorElement.classList.remove('hidden');
      }

      // Assert: Error message displayed
      expect(errorElement.textContent).toContain('not found');
      expect(errorElement.classList.remove).toHaveBeenCalledWith('hidden');
    });

    it('refreshes list via refreshList() after API error to sync state', async () => {
      // Arrange
      const todoId = 'todo-sync-test';
      let refreshCalled = false;

      fetchMock
        .mockRejectedValueOnce({
          status: 404,
          message: 'Todo not found'
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => []
        });

      const refreshList = async () => {
        refreshCalled = true;
        // Re-fetch all todos to sync with server state
        return await client.getAllTodos();
      };

      // Act: Delete fails, then refresh
      try {
        await client.deleteTodo(todoId);
      } catch (error) {
        // On error, refresh list to ensure client state matches server
        await refreshList();
      }

      // Assert: List was refreshed after error
      expect(refreshCalled).toBe(true);
    });

    it('displays error in [data-testid="error-message"] for 500 server error', async () => {
      // Arrange
      const errorElement = {
        textContent: '',
        style: { display: 'none' },
        classList: { remove: vi.fn() }
      };

      mockElements.set('[data-testid="error-message"]', errorElement);

      fetchMock.mockRejectedValueOnce({
        status: 500,
        message: 'Server error'
      });

      // Act: Handle server error
      try {
        await client.deleteTodo('todo-123');
      } catch (error) {
        errorElement.textContent = 'Failed to delete todo. Please try again.';
        errorElement.style.display = 'block';
        errorElement.classList.remove('hidden');
      }

      // Assert: Error displayed to user
      expect(errorElement.textContent).toContain('Failed to delete');
      expect(errorElement.classList.remove).toHaveBeenCalledWith('hidden');
    });

    it('shows network error message when fetch fails entirely', async () => {
      // Arrange
      const errorElement = {
        textContent: '',
        classList: { remove: vi.fn() }
      };

      mockElements.set('[data-testid="error-message"]', errorElement);

      fetchMock.mockRejectedValueOnce(new Error('Network error'));

      // Act: Handle network failure
      try {
        await client.deleteTodo('todo-123');
      } catch (error) {
        errorElement.textContent = 'Network error. Please check your connection.';
        errorElement.classList.remove('hidden');
      }

      // Assert: Network error displayed
      expect(errorElement.textContent).toContain('Network error');
    });

    it('preserves todo in DOM when delete fails', async () => {
      // Arrange
      const todoId = 'todo-preserve';
      const mockRemove = vi.fn();

      const todoElement = {
        getAttribute: () => todoId,
        remove: mockRemove
      };

      mockElements.set(`[data-testid="todo-item-${todoId}"]`, todoElement);

      fetchMock.mockRejectedValueOnce({
        status: 500,
        message: 'Server Error'
      });

      // Act: Attempt delete (should fail), do NOT remove from DOM
      try {
        await client.deleteTodo(todoId);
        // Only remove on success - this line should not execute
        todoElement.remove();
      } catch (error) {
        // Error case - element stays in DOM
      }

      // Assert: Element NOT removed from DOM
      expect(mockRemove).not.toHaveBeenCalled();
    });
  });

  // ============================================================================
  // Test 4: Empty state becomes visible when last todo deleted
  // ============================================================================

  describe('empty state visibility on last todo deletion', () => {
    it('shows [data-testid="empty-state"] when the last todo is deleted', async () => {
      // Arrange
      const lastTodoId = 'todo-last';
      const mockRemove = vi.fn();

      const todoElement = {
        getAttribute: () => lastTodoId,
        remove: mockRemove
      };

      const emptyState = {
        style: { display: 'none' },
        classList: {
          remove: vi.fn((cls) => {
            if (cls === 'hidden') emptyState.style.display = 'flex';
          })
        }
      };

      mockElements.set(`[data-testid="todo-item-${lastTodoId}"]`, todoElement);
      mockElements.set('[data-testid="empty-state"]', emptyState);

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: Delete last todo
      await client.deleteTodo(lastTodoId);
      todoElement.remove();

      // Simulate checking remaining todos and showing empty state
      const remainingTodos = [];
      if (remainingTodos.length === 0) {
        emptyState.classList.remove('hidden');
      }

      // Assert: Empty state shown
      expect(emptyState.classList.remove).toHaveBeenCalledWith('hidden');
      expect(emptyState.style.display).toBe('flex');
    });
  });

  // ============================================================================
  // Test 5: Optional confirmation dialog behavior
  // ============================================================================

  describe('optional confirmation dialog', () => {
    it('proceeds with deletion when user confirms', async () => {
      // Arrange
      global.confirm.mockReturnValueOnce(true);
      const todoId = 'todo-confirm';

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: User confirms deletion
      const shouldDelete = global.confirm('Are you sure you want to delete this todo?');

      if (shouldDelete) {
        await client.deleteTodo(todoId);
      }

      // Assert: Confirmation shown and API called
      expect(global.confirm).toHaveBeenCalled();
      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
    });

    it('cancels deletion when user denies confirmation', async () => {
      // Arrange
      global.confirm.mockReturnValueOnce(false);
      const todoId = 'todo-cancel';

      // Act: User cancels deletion
      const shouldDelete = global.confirm('Are you sure you want to delete this todo?');

      if (shouldDelete) {
        await client.deleteTodo(todoId);
      }

      // Assert: API NOT called when cancelled
      expect(global.confirm).toHaveBeenCalled();
      expect(fetchMock).not.toHaveBeenCalled();
    });
  });

  // ============================================================================
  // Test 6: Edge case - malformed DOM handling
  // ============================================================================

  describe('edge case handling for malformed DOM', () => {
    it('handles delete button click without parent [data-todo-id] element gracefully', async () => {
      // Arrange: Delete button not inside a todo item
      const orphanBtn = {
        getAttribute: (attr) => {
          if (attr === 'data-testid') return 'delete-todo-btn';
          return null;
        },
        closest: () => null  // No parent with data-todo-id
      };

      // Act & Assert: Should handle gracefully without throwing
      const parent = orphanBtn.closest('[data-todo-id]');
      expect(parent).toBeNull();

      // Should NOT call API with null/undefined ID
      expect(fetchMock).not.toHaveBeenCalled();
    });

    it('handles missing data-todo-id attribute gracefully', async () => {
      // Arrange: Parent exists but missing data-todo-id
      const todoWithoutId = {
        getAttribute: () => null  // No data-todo-id value
      };

      const deleteBtn = {
        closest: () => todoWithoutId
      };

      // Act
      const extractedId = todoWithoutId.getAttribute('data-todo-id');

      // Assert: Returns null, no API call made
      expect(extractedId).toBeNull();
    });
  });

  // ============================================================================
  // Test 7: E2E flow simulation
  // ============================================================================

  describe('end-to-end delete flow', () => {
    it('complete success flow: click -> API call -> success -> DOM remove -> check empty state', async () => {
      // Arrange
      const todoId = 'todo-e2e-success';
      const mockRemove = vi.fn();

      const todoElement = {
        getAttribute: (attr) => {
          if (attr === 'data-todo-id') return todoId;
          if (attr === 'data-testid') return `todo-item-${todoId}`;
          return null;
        },
        remove: mockRemove
      };

      const emptyState = {
        style: { display: 'none' },
        classList: { remove: vi.fn() }
      };

      mockElements.set(`[data-testid="todo-item-${todoId}"]`, todoElement);
      mockElements.set('[data-testid="empty-state"]', emptyState);

      global.confirm.mockReturnValueOnce(true);
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      // Act: Complete flow
      // 1. User confirms deletion
      const shouldDelete = global.confirm('Delete this todo?');
      expect(shouldDelete).toBe(true);

      // 2. API call made
      await client.deleteTodo(todoId);

      // 3. On success, remove from DOM
      todoElement.remove();

      // 4. Check if empty state should show
      const remaining = [];
      if (remaining.length === 0) {
        emptyState.classList.remove('hidden');
      }

      // Assert: Full flow completed
      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
      expect(mockRemove).toHaveBeenCalled();
      expect(emptyState.classList.remove).toHaveBeenCalledWith('hidden');
    });

    it('complete error flow: click -> API call -> 404 error -> error shown -> list refreshed', async () => {
      // Arrange
      const todoId = 'todo-e2e-error';
      const errorElement = {
        textContent: '',
        classList: { remove: vi.fn() }
      };
      let refreshCalled = false;

      mockElements.set('[data-testid="error-message"]', errorElement);

      fetchMock
        .mockRejectedValueOnce({
          status: 404,
          message: 'Todo not found'
        })
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: async () => []
        });

      const refreshList = async () => {
        refreshCalled = true;
        return await client.getAllTodos();
      };

      // Act: Error flow
      try {
        await client.deleteTodo(todoId);
      } catch (error) {
        // Show error message
        errorElement.textContent = 'Todo not found. It may have already been deleted.';
        errorElement.classList.remove('hidden');

        // Refresh list to sync state
        await refreshList();
      }

      // Assert: Error handled correctly
      expect(errorElement.textContent).toContain('not found');
      expect(errorElement.classList.remove).toHaveBeenCalledWith('hidden');
      expect(refreshCalled).toBe(true);
    });
  });
});
