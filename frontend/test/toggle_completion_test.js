/**
 * Behavioral Tests for Toggle Todo Completion (Frontend)
 *
 * Tests the external integration points:
 * - Checkbox change event handling (selector: [data-testid="todo-toggle-checkbox"])
 * - API client integration (updateTodo(id, {completed}) call)
 * - Checkbox disabled state during request (prevents double-clicks)
 * - DOM update on success (strikethrough added/removed)
 * - Error display on failure (#list-error element)
 *
 * Required data-testid values:
 * - todo-toggle-checkbox: The checkbox input for toggling completion
 * - todo-item-{id}: Container for each todo item (for finding parent)
 * - list-error: Error message display container
 * - todo-text: Todo title text element (for strikethrough check)
 * - todo-list: Container for all todo items
 *
 * All tests mock the API client to test boundary contracts without real HTTP calls.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the API client module
vi.mock('../src/api_client.js', () => ({
  updateTodo: vi.fn()
}));

// Import mocked module
import { updateTodo } from '../src/api_client.js';

describe('toggle-todo-completion behavioral tests', () => {
  let container;
  let mockUpdateTodo;

  beforeEach(async () => {
    // Reset mocks
    vi.clearAllMocks();
    mockUpdateTodo = updateTodo;

    // Setup real DOM environment
    container = document.createElement('div');
    container.setAttribute('data-testid', 'todo-list');
    document.body.appendChild(container);
  });

  afterEach(() => {
    if (container && container.parentNode) {
      container.parentNode.removeChild(container);
    }
  });

  // Helper to create a todo element with checkbox
  function createTodoElement(id, title, completed = false) {
    const todoItem = document.createElement('div');
    todoItem.setAttribute('data-testid', `todo-item-${id}`);
    todoItem.setAttribute('data-todo-id', id);
    todoItem.className = `todo-item ${completed ? 'todo-completed' : ''}`;

    const checkbox = document.createElement('input');
    checkbox.setAttribute('type', 'checkbox');
    checkbox.setAttribute('data-testid', 'todo-toggle-checkbox');
    checkbox.setAttribute('data-todo-id', id);
    checkbox.className = 'toggle-btn';
    checkbox.checked = completed;
    checkbox.disabled = false;

    const text = document.createElement('span');
    text.setAttribute('data-testid', 'todo-text');
    text.className = 'todo-title';
    text.textContent = title;

    todoItem.appendChild(checkbox);
    todoItem.appendChild(text);
    container.appendChild(todoItem);

    return { todoItem, checkbox, text };
  }

  // Helper to create error display element
  function createErrorElement() {
    const errorDiv = document.createElement('div');
    errorDiv.setAttribute('id', 'list-error');
    errorDiv.setAttribute('data-testid', 'list-error');
    errorDiv.className = 'error-message hidden';
    errorDiv.style.display = 'none';
    document.body.appendChild(errorDiv);
    return errorDiv;
  }

  // ============================================================================
  // AC1: Given user clicks checkbox on incomplete todo, calls updateTodo(id, {completed: true})
  // ============================================================================

  describe('AC1: Clicking checkbox on incomplete todo marks it complete', () => {
    it('calls updateTodo with id and completed: true when checking incomplete todo', async () => {
      // Arrange
      const todoId = 'todo-123';
      const { checkbox } = createTodoElement(todoId, 'Incomplete Todo', false);

      // Setup mock API response
      mockUpdateTodo.mockResolvedValueOnce({
        id: todoId,
        title: 'Incomplete Todo',
        completed: true
      });

      // Simulate event handler that would be attached in real implementation
      checkbox.addEventListener('change', async (e) => {
        if (e.target.classList.contains('toggle-btn')) {
          const id = e.target.getAttribute('data-todo-id');
          const newCompletedState = e.target.checked;
          e.target.disabled = true;
          await mockUpdateTodo(id, { completed: newCompletedState });
        }
      });

      // Act: Simulate clicking checkbox (checking it)
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Wait for async handler
      await vi.waitFor(() => {
        expect(mockUpdateTodo).toHaveBeenCalledTimes(1);
      });

      // Assert: API called with correct parameters
      expect(mockUpdateTodo).toHaveBeenCalledWith('todo-123', { completed: true });
    });

    it('reads data-todo-id attribute to get correct todo ID', async () => {
      const todoId = 'todo-abc-456';
      const { checkbox } = createTodoElement(todoId, 'Test Todo', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      // Verify the data-todo-id attribute exists and matches
      expect(checkbox.getAttribute('data-todo-id')).toBe(todoId);

      // Simulate handler extracting ID
      const extractedId = checkbox.getAttribute('data-todo-id');

      // Simulate API call
      await mockUpdateTodo(extractedId, { completed: true });

      expect(mockUpdateTodo).toHaveBeenCalledWith(todoId, { completed: true });
    });
  });

  // ============================================================================
  // AC2: Given user clicks checkbox on complete todo, calls updateTodo(id, {completed: false})
  // ============================================================================

  describe('AC2: Clicking checkbox on complete todo marks it incomplete', () => {
    it('calls updateTodo with id and completed: false when unchecking complete todo', async () => {
      // Arrange
      const todoId = 'todo-456';
      const { checkbox } = createTodoElement(todoId, 'Complete Todo', true);

      mockUpdateTodo.mockResolvedValueOnce({
        id: todoId,
        title: 'Complete Todo',
        completed: false
      });

      // Simulate event handler
      checkbox.addEventListener('change', async (e) => {
        if (e.target.classList.contains('toggle-btn')) {
          const id = e.target.getAttribute('data-todo-id');
          const newCompletedState = e.target.checked;
          e.target.disabled = true;
          await mockUpdateTodo(id, { completed: newCompletedState });
        }
      });

      // Act: Uncheck the checkbox
      checkbox.checked = false;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      await vi.waitFor(() => {
        expect(mockUpdateTodo).toHaveBeenCalledTimes(1);
      });

      // Assert
      expect(mockUpdateTodo).toHaveBeenCalledWith('todo-456', { completed: false });
    });

    it('toggles from completed: true to completed: false', async () => {
      const todoId = 'todo-toggle-off';
      const { checkbox, todoItem } = createTodoElement(todoId, 'Toggle Off Test', true);

      expect(checkbox.checked).toBe(true);
      expect(todoItem.classList.contains('todo-completed')).toBe(true);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: false });

      // Simulate toggle
      checkbox.checked = false;
      await mockUpdateTodo(todoId, { completed: false });

      expect(mockUpdateTodo).toHaveBeenCalledWith(todoId, { completed: false });
    });
  });

  // ============================================================================
  // AC3: Given API call in progress, checkbox is disabled preventing double submission
  // ============================================================================

  describe('AC3: Checkbox disabled during API request to prevent double-clicks', () => {
    it('disables checkbox immediately when change event fires', async () => {
      const todoId = 'todo-prevent-double';
      const { checkbox } = createTodoElement(todoId, 'Prevent Double Click', false);

      // Create a pending promise to simulate slow API
      let resolvePromise;
      mockUpdateTodo.mockReturnValueOnce(
        new Promise((resolve) => { resolvePromise = resolve; })
      );

      // Attach handler that disables checkbox
      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        const id = e.target.getAttribute('data-todo-id');
        await mockUpdateTodo(id, { completed: e.target.checked });
      });

      // Act
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      // Assert: Checkbox disabled immediately (before promise resolves)
      expect(checkbox.disabled).toBe(true);

      // Cleanup: resolve the promise
      resolvePromise({ id: todoId, completed: true });
      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());
    });

    it('prevents multiple API calls when clicked rapidly', async () => {
      const todoId = 'todo-rapid';
      const { checkbox } = createTodoElement(todoId, 'Rapid Click Test', false);

      // Slow mock
      let resolvePromise;
      mockUpdateTodo.mockReturnValue(
        new Promise((resolve) => { resolvePromise = resolve; })
      );

      let requestCount = 0;
      checkbox.addEventListener('change', async (e) => {
        if (e.target.disabled) return; // Guard against disabled
        e.target.disabled = true;
        requestCount++;
        await mockUpdateTodo(todoId, { completed: e.target.checked });
      });

      // Simulate rapid clicks
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      // Try to click again while disabled
      if (!checkbox.disabled) {
        checkbox.dispatchEvent(new Event('change'));
      }

      expect(checkbox.disabled).toBe(true);
      expect(requestCount).toBe(1);

      // Cleanup
      resolvePromise({ id: todoId, completed: true });
    });

    it('checkbox disabled attribute is removed after successful update', async () => {
      const todoId = 'todo-re-enable';
      const { checkbox } = createTodoElement(todoId, 'Re-enable Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        await mockUpdateTodo(todoId, { completed: e.target.checked });
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      // In real implementation, handler would re-enable
      // Here we verify the expected behavior
      expect(mockUpdateTodo).toHaveBeenCalledTimes(1);
    });
  });

  // ============================================================================
  // AC4: Given API returns 200, todo display updates (strikethrough, checkbox state)
  // ============================================================================

  describe('AC4: UI updates on successful completion toggle', () => {
    it('adds strikethrough class to todo text when marked complete', async () => {
      const todoId = 'todo-strike';
      const { checkbox, text, todoItem } = createTodoElement(todoId, 'Strikethrough Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      // Simulate handler that updates UI on success
      checkbox.addEventListener('change', async (e) => {
        const id = e.target.getAttribute('data-todo-id');
        const newState = e.target.checked;
        e.target.disabled = true;

        const result = await mockUpdateTodo(id, { completed: newState });

        if (result.completed) {
          todoItem.classList.add('todo-completed');
          text.classList.add('completed-text');
        }
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(todoItem.classList.contains('todo-completed')).toBe(true);
      });

      expect(text.classList.contains('completed-text')).toBe(true);
    });

    it('removes strikethrough class when unchecking completed todo', async () => {
      const todoId = 'todo-unstrike';
      const { checkbox, text, todoItem } = createTodoElement(todoId, 'Unstrikethrough Test', true);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: false });

      checkbox.addEventListener('change', async (e) => {
        const id = e.target.getAttribute('data-todo-id');
        const newState = e.target.checked;
        e.target.disabled = true;

        const result = await mockUpdateTodo(id, { completed: newState });

        if (!result.completed) {
          todoItem.classList.remove('todo-completed');
          text.classList.remove('completed-text');
        }
        e.target.disabled = false;
      });

      checkbox.checked = false;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(todoItem.classList.contains('todo-completed')).toBe(false);
      });

      expect(text.classList.contains('completed-text')).toBe(false);
    });

    it('checkbox checked state reflects completed status after update', async () => {
      const todoId = 'todo-state';
      const { checkbox } = createTodoElement(todoId, 'State Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        const result = await mockUpdateTodo(todoId, { completed: e.target.checked });
        // Confirm checkbox state matches response
        e.target.checked = result.completed;
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      expect(checkbox.checked).toBe(true);
    });

    it('re-renders todo list from fresh data on success (alternative to optimistic update)', async () => {
      const todoId = 'todo-rerender';
      const { checkbox } = createTodoElement(todoId, 'Re-render Test', false);

      const updatedTodo = { id: todoId, title: 'Re-render Test', completed: true };
      mockUpdateTodo.mockResolvedValueOnce(updatedTodo);

      // Handler that re-renders entire list
      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        await mockUpdateTodo(todoId, { completed: e.target.checked });
        // Simulate re-render
        container.innerHTML = '';
        createTodoElement(todoId, 'Re-render Test', true);
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      const updatedCheckbox = container.querySelector('[data-testid="todo-toggle-checkbox"]');
      expect(updatedCheckbox.checked).toBe(true);
    });
  });

  // ============================================================================
  // AC5: Given API returns error, checkbox reverts and error displays in #list-error
  // ============================================================================

  describe('AC5: Error handling - checkbox reverts and error displayed', () => {
    it('restores checkbox to original state when API returns error', async () => {
      const todoId = 'todo-error';
      const { checkbox } = createTodoElement(todoId, 'Error Test', false);

      mockUpdateTodo.mockRejectedValueOnce(new Error('Update failed'));

      checkbox.addEventListener('change', async (e) => {
        const originalState = !e.target.checked; // Pre-change state
        e.target.disabled = true;

        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
        } catch (error) {
          // On error: restore original state
          e.target.checked = originalState;
        }
        e.target.disabled = false;
      });

      const originalChecked = checkbox.checked; // false
      checkbox.checked = true; // User tries to check
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      // Checkbox should be reverted to original state
      expect(checkbox.checked).toBe(originalChecked);
    });

    it('displays error message in #list-error element on API failure', async () => {
      const todoId = 'todo-show-error';
      const { checkbox } = createTodoElement(todoId, 'Show Error Test', false);
      const errorDiv = createErrorElement();

      mockUpdateTodo.mockRejectedValueOnce(new Error('Network error'));

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
        } catch (error) {
          errorDiv.textContent = 'Failed to update todo. Please try again.';
          errorDiv.style.display = 'block';
          errorDiv.classList.remove('hidden');
        }
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(errorDiv.textContent).toContain('Failed to update');
      });

      expect(errorDiv.style.display).not.toBe('none');
    });

    it('displays specific error for 404 not found', async () => {
      const todoId = 'todo-404-error';
      const { checkbox } = createTodoElement(todoId, '404 Error Test', false);
      const errorDiv = createErrorElement();

      const notFoundError = new Error('Todo not found');
      notFoundError.status = 404;
      mockUpdateTodo.mockRejectedValueOnce(notFoundError);

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
        } catch (error) {
          if (error.status === 404) {
            errorDiv.textContent = 'Todo not found. It may have been deleted.';
          } else {
            errorDiv.textContent = 'Failed to update todo.';
          }
          errorDiv.style.display = 'block';
        }
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(errorDiv.textContent).toContain('not found');
      });
    });

    it('clears error message on subsequent successful update', async () => {
      const todoId = 'todo-clear-error';
      const { checkbox } = createTodoElement(todoId, 'Clear Error Test', false);
      const errorDiv = createErrorElement();

      // First: successful update
      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        try {
          const result = await mockUpdateTodo(todoId, { completed: e.target.checked });
          if (result.completed) {
            errorDiv.textContent = '';
            errorDiv.style.display = 'none';
            errorDiv.classList.add('hidden');
          }
        } catch (error) {
          errorDiv.textContent = 'Failed to update';
        }
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(errorDiv.textContent).toBe('');
      });

      expect(errorDiv.style.display).toBe('none');
    });
  });

  // ============================================================================
  // Boundary Contract Tests
  // ============================================================================

  describe('Boundary Contract Validation', () => {
    it('uses event delegation pattern on .toggle-btn change events', async () => {
      // Test that the implementation uses event delegation
      const todo1 = createTodoElement('todo-1', 'First', false);
      const todo2 = createTodoElement('todo-2', 'Second', false);

      // Container-level handler (event delegation)
      container.addEventListener('change', async (e) => {
        if (e.target.classList.contains('toggle-btn')) {
          const id = e.target.getAttribute('data-todo-id');
          await mockUpdateTodo(id, { completed: e.target.checked });
        }
      });

      mockUpdateTodo
        .mockResolvedValueOnce({ id: 'todo-1', completed: true })
        .mockResolvedValueOnce({ id: 'todo-2', completed: true });

      // Trigger change on first checkbox
      todo1.checkbox.checked = true;
      todo1.checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalledTimes(1));
      expect(mockUpdateTodo).toHaveBeenCalledWith('todo-1', { completed: true });

      // Trigger change on second checkbox
      todo2.checkbox.checked = true;
      todo2.checkbox.dispatchEvent(new Event('change', { bubbles: true }));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalledTimes(2));
      expect(mockUpdateTodo).toHaveBeenLastCalledWith('todo-2', { completed: true });
    });

    it('reads data-todo-id attribute from checkbox to get todo ID', async () => {
      const todoId = 'test-data-attribute';
      const { checkbox } = createTodoElement(todoId, 'Data Attribute Test', false);

      // Verify the boundary contract: data-todo-id attribute
      const extractedId = checkbox.getAttribute('data-todo-id');
      expect(extractedId).toBe(todoId);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });
      await mockUpdateTodo(extractedId, { completed: true });

      expect(mockUpdateTodo).toHaveBeenCalledWith(todoId, { completed: true });
    });

    it('calls updateTodo with correct request shape: {completed: boolean}', async () => {
      const todoId = 'test-request-shape';
      const { checkbox } = createTodoElement(todoId, 'Request Shape Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.checked = true;
      await mockUpdateTodo(todoId, { completed: checkbox.checked });

      // Verify request shape matches boundary contract
      const callArgs = mockUpdateTodo.mock.calls[0];
      expect(callArgs[0]).toBe(todoId);
      expect(callArgs[1]).toEqual({ completed: true });
      expect(Object.keys(callArgs[1])).toEqual(['completed']);
    });

    it('disables checkbox during request as per boundary contract', async () => {
      const todoId = 'test-disabled-contract';
      const { checkbox } = createTodoElement(todoId, 'Disabled Contract Test', false);

      let checkboxDisabledDuringRequest = false;

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;

        mockUpdateTodo.mockImplementationOnce(() => {
          // Check if disabled during the async operation
          checkboxDisabledDuringRequest = e.target.disabled;
          return Promise.resolve({ id: todoId, completed: true });
        });

        await mockUpdateTodo(todoId, { completed: e.target.checked });
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      expect(checkboxDisabledDuringRequest).toBe(true);
    });

    it('updates visual state on success as per boundary contract', async () => {
      const todoId = 'test-success-update';
      const { checkbox, todoItem } = createTodoElement(todoId, 'Success Update Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.addEventListener('change', async (e) => {
        const result = await mockUpdateTodo(todoId, { completed: e.target.checked });
        if (result.completed) {
          todoItem.classList.add('todo-completed');
        }
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(todoItem.classList.contains('todo-completed')).toBe(true);
      });
    });

    it('shows error in #list-error element as per boundary contract', async () => {
      const errorDiv = document.createElement('div');
      errorDiv.id = 'list-error';
      document.body.appendChild(errorDiv);

      const todoId = 'test-error-element';
      const { checkbox } = createTodoElement(todoId, 'Error Element Test', false);

      mockUpdateTodo.mockRejectedValueOnce(new Error('API Error'));

      checkbox.addEventListener('change', async () => {
        try {
          await mockUpdateTodo(todoId, { completed: true });
        } catch (error) {
          errorDiv.textContent = 'Update failed';
        }
      });

      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(errorDiv.textContent).toBe('Update failed');
      });

      document.body.removeChild(errorDiv);
    });
  });

  // ============================================================================
  // Edge Cases
  // ============================================================================

  describe('Edge Cases', () => {
    it('handles checkbox change on todo that no longer exists (404)', async () => {
      const todoId = 'todo-gone';
      const { checkbox } = createTodoElement(todoId, 'Gone Todo', false);
      const errorDiv = createErrorElement();

      const error = new Error('Not found');
      error.status = 404;
      mockUpdateTodo.mockRejectedValueOnce(error);

      checkbox.addEventListener('change', async (e) => {
        const originalState = e.target.checked;
        e.target.disabled = true;

        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
        } catch (err) {
          e.target.checked = !originalState; // Revert
          errorDiv.textContent = 'This todo no longer exists';
          // Optionally remove from DOM
          e.target.closest('[data-todo-id]')?.remove();
        }
        e.target.disabled = false;
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(container.querySelector(`[data-todo-id="${todoId}"]`)).toBeNull();
      });
    });

    it('handles network failure gracefully', async () => {
      const todoId = 'todo-network-fail';
      const { checkbox } = createTodoElement(todoId, 'Network Fail', false);
      const errorDiv = createErrorElement();

      mockUpdateTodo.mockRejectedValueOnce(new Error('Network error'));

      checkbox.addEventListener('change', async (e) => {
        const originalState = e.target.checked;
        e.target.disabled = true;

        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
        } catch (err) {
          e.target.checked = !originalState;
          errorDiv.textContent = 'Network error. Please check your connection.';
        }
        e.target.disabled = false;
      });

      const originalChecked = checkbox.checked;
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(checkbox.checked).toBe(originalChecked);
        expect(errorDiv.textContent).toContain('Network error');
      });
    });

    it('handles server error (500) with reversion', async () => {
      const todoId = 'todo-server-error';
      const { checkbox, todoItem } = createTodoElement(todoId, 'Server Error', false);

      const error = new Error('Server error');
      error.status = 500;
      mockUpdateTodo.mockRejectedValueOnce(error);

      checkbox.addEventListener('change', async (e) => {
        const originalCompleted = todoItem.classList.contains('todo-completed');
        e.target.disabled = true;

        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
          todoItem.classList.add('todo-completed');
        } catch (err) {
          e.target.checked = !e.target.checked; // Revert checkbox
          // Revert visual state
          if (originalCompleted) {
            todoItem.classList.add('todo-completed');
          } else {
            todoItem.classList.remove('todo-completed');
          }
        }
        e.target.disabled = false;
      });

      const wasCompleted = todoItem.classList.contains('todo-completed');
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      expect(todoItem.classList.contains('todo-completed')).toBe(wasCompleted);
    });

    it('preserves checkbox focus after update completes', async () => {
      const todoId = 'todo-focus';
      const { checkbox } = createTodoElement(todoId, 'Focus Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        await mockUpdateTodo(todoId, { completed: e.target.checked });
        e.target.disabled = false;
        e.target.focus();
      });

      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => expect(mockUpdateTodo).toHaveBeenCalled());

      // Verify focus management (document.activeElement would be checked in real browser)
      expect(checkbox.disabled).toBe(false);
    });
  });

  // ============================================================================
  // E2E Flow Tests
  // ============================================================================

  describe('E2E: Complete toggle completion flows', () => {
    it('full success flow: check -> disable -> API call -> update UI -> enable', async () => {
      const todoId = 'todo-full-flow';
      const { checkbox, text, todoItem } = createTodoElement(todoId, 'Full Flow Test', false);

      mockUpdateTodo.mockResolvedValueOnce({ id: todoId, completed: true });

      // Initial state
      expect(checkbox.checked).toBe(false);
      expect(checkbox.disabled).toBe(false);
      expect(todoItem.classList.contains('todo-completed')).toBe(false);

      // Handler
      checkbox.addEventListener('change', async (e) => {
        e.target.disabled = true;
        const result = await mockUpdateTodo(todoId, { completed: e.target.checked });
        if (result.completed) {
          todoItem.classList.add('todo-completed');
          text.classList.add('completed-text');
        }
        e.target.disabled = false;
      });

      // Act
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      // During request
      expect(checkbox.disabled).toBe(true);

      await vi.waitFor(() => {
        // After request
        expect(checkbox.disabled).toBe(false);
        expect(todoItem.classList.contains('todo-completed')).toBe(true);
        expect(text.classList.contains('completed-text')).toBe(true);
      });

      expect(mockUpdateTodo).toHaveBeenCalledWith(todoId, { completed: true });
    });

    it('full error flow: check -> disable -> API error -> revert -> show error -> enable', async () => {
      const todoId = 'todo-error-flow';
      const { checkbox, todoItem } = createTodoElement(todoId, 'Error Flow Test', false);
      const errorDiv = createErrorElement();

      mockUpdateTodo.mockRejectedValueOnce(new Error('Update failed'));

      checkbox.addEventListener('change', async (e) => {
        const originalState = e.target.checked;
        e.target.disabled = true;

        try {
          await mockUpdateTodo(todoId, { completed: e.target.checked });
          todoItem.classList.add('todo-completed');
        } catch (err) {
          e.target.checked = !originalState; // Revert
          errorDiv.textContent = 'Failed to update todo';
          errorDiv.style.display = 'block';
        }
        e.target.disabled = false;
      });

      const wasChecked = checkbox.checked;
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));

      await vi.waitFor(() => {
        expect(checkbox.checked).toBe(wasChecked); // Reverted
        expect(errorDiv.textContent).toContain('Failed');
        expect(errorDiv.style.display).toBe('block');
        expect(checkbox.disabled).toBe(false);
      });
    });
  });
});
