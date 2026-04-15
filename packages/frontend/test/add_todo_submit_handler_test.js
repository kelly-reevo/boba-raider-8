/**
 * Behavioral Tests for add-todo-submit-handler
 *
 * Tests the external integration points:
 * - Form submission handling with preventDefault
 * - Input validation at boundary
 * - todo-store-create operation invocation
 * - Input clearing after successful submission
 * - List re-render triggering
 *
 * Required data-testid attributes:
 * - add-todo-form: The form container element
 * - todo-title-input: The text input for todo title
 * - add-todo-btn: The Add button
 * - todo-list: The container for todo items
 * - todo-item: Individual todo items in the list
 * - validation-error: Error message display element
 *
 * Boundary contracts:
 * - Input: form submit event or Enter keydown event
 * - Output: calls create(title) with trimmed string, clears input, triggers re-render
 * - Error case: displays validation error, does not call create
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the todo store module before importing the handler
const mockTodoStoreCreate = vi.fn();
const mockRenderTodoList = vi.fn();

vi.mock('../src/todo_store.js', () => ({
  create: mockTodoStoreCreate
}));

vi.mock('../src/todo_list_renderer.js', () => ({
  renderTodoList: mockRenderTodoList
}));

// Import the handler under test
import { handleAddTodoSubmit, initAddTodoForm } from '../src/add_todo_submit_handler.js';

describe('add-todo-submit-handler behavioral tests', () => {
  let form;
  let input;
  let addButton;
  let todoListContainer;

  beforeEach(() => {
    // Reset mocks
    mockTodoStoreCreate.mockClear();
    mockRenderTodoList.mockClear();

    // Create fresh DOM elements for each test with required data-testid attributes
    form = document.createElement('form');
    form.setAttribute('data-testid', 'add-todo-form');

    input = document.createElement('input');
    input.setAttribute('data-testid', 'todo-title-input');
    input.type = 'text';

    addButton = document.createElement('button');
    addButton.setAttribute('data-testid', 'add-todo-btn');
    addButton.type = 'submit';

    form.appendChild(input);
    form.appendChild(addButton);

    todoListContainer = document.createElement('div');
    todoListContainer.setAttribute('data-testid', 'todo-list');

    document.body.appendChild(form);
    document.body.appendChild(todoListContainer);
  });

  afterEach(() => {
    // Clean up DOM
    if (form && form.parentNode) form.parentNode.removeChild(form);
    if (todoListContainer && todoListContainer.parentNode) {
      todoListContainer.parentNode.removeChild(todoListContainer);
    }
  });

  describe('AC1: Valid submission creates todo, clears input, re-renders list', () => {
    it('calls todo-store-create with trimmed title when form is submitted', () => {
      input.value = 'Buy milk';

      // Simulate form submission
      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledTimes(1);
      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('calls create with trimmed string when input has leading/trailing whitespace', () => {
      input.value = '  Buy milk  ';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('calls preventDefault to stop form from reloading page', () => {
      input.value = 'Buy milk';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault');

      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(preventDefaultSpy).toHaveBeenCalledTimes(1);
    });

    it('clears input value after successful creation', () => {
      input.value = 'Buy milk';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(input.value).toBe('');
    });

    it('triggers list re-render after successful creation', () => {
      input.value = 'Buy milk';
      mockTodoStoreCreate.mockReturnValue({ id: 'todo-1', title: 'Buy milk', completed: false });

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockRenderTodoList).toHaveBeenCalledTimes(1);
      expect(mockRenderTodoList).toHaveBeenCalledWith(todoListContainer);
    });

    it('re-renders list with new item visible after creation', () => {
      input.value = 'Buy milk';
      const newTodo = { id: 'todo-1', title: 'Buy milk', completed: false };
      mockTodoStoreCreate.mockReturnValue(newTodo);

      // Setup mock to simulate adding item to DOM during re-render
      mockRenderTodoList.mockImplementation((container) => {
        const todoItem = document.createElement('div');
        todoItem.setAttribute('data-testid', 'todo-item');
        todoItem.setAttribute('data-todo-id', newTodo.id);
        todoItem.textContent = newTodo.title;
        container.appendChild(todoItem);
      });

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      const todoItems = todoListContainer.querySelectorAll('[data-testid="todo-item"]');
      expect(todoItems.length).toBe(1);
      expect(todoItems[0].textContent).toBe('Buy milk');
    });
  });

  describe('AC2: Empty input shows validation error, no todo created', () => {
    it('does not call todo-store-create when input is empty', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('does not call todo-store-create when input contains only whitespace', () => {
      input.value = '   ';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('displays validation error when input is empty', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      // Handler should add error display near input or form
      const errorElement = form.querySelector('[data-testid="validation-error"]') ||
                          document.querySelector('[data-testid="validation-error"]');
      expect(errorElement).not.toBeNull();
      expect(errorElement.textContent).toContain('empty');
    });

    it('does not trigger list re-render when validation fails', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockRenderTodoList).not.toHaveBeenCalled();
    });

    it('prevents form submission even when validation fails', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault');

      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(preventDefaultSpy).toHaveBeenCalledTimes(1);
    });

    it('does not clear input when validation fails', () => {
      input.value = '   '; // Whitespace only, should fail validation

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      // Input should remain unchanged (or cleared to empty, but not modified to different value)
      expect(input.value).toBe('   ');
    });
  });

  describe('AC3: Pressing Enter triggers same behavior as clicking Add button', () => {
    it('calls todo-store-create when Enter key is pressed in input', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledTimes(1);
      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('prevents default behavior on Enter key to avoid form double-submit', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      const preventDefaultSpy = vi.spyOn(keydownEvent, 'preventDefault');

      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(preventDefaultSpy).toHaveBeenCalledTimes(1);
    });

    it('does not create todo when Enter pressed with empty input', () => {
      input.value = '';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('clears input after Enter key submission', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(input.value).toBe('');
    });

    it('re-renders list after Enter key submission', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockRenderTodoList).toHaveBeenCalledTimes(1);
    });

    it('ignores non-Enter keys in input field', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Escape',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
      expect(input.value).toBe('Buy milk'); // Input unchanged
    });

    it('ignores Shift+Enter to allow multiline input if supported', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        shiftKey: true,
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      // Should NOT submit on Shift+Enter (allows potential future multiline)
      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });
  });

  describe('Boundary Contract: Input trimming behavior', () => {
    it('trims leading whitespace from input before creating todo', () => {
      input.value = '   Buy milk';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('trims trailing whitespace from input before creating todo', () => {
      input.value = 'Buy milk   ';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('trims both leading and trailing whitespace', () => {
      input.value = '  Buy milk  ';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('preserves internal whitespace in the middle of text', () => {
      input.value = 'Buy  milk  and  cookies';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy  milk  and  cookies');
    });

    it('handles tab characters as whitespace to trim', () => {
      input.value = '\tBuy milk\t';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });
  });

  describe('Edge Cases', () => {
    it('handles very long todo titles', () => {
      const longTitle = 'A'.repeat(500);
      input.value = longTitle;

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith(longTitle);
    });

    it('handles special characters in todo titles', () => {
      input.value = 'Buy milk & eggs <script>alert(1)</script>';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk & eggs <script>alert(1)</script>');
    });

    it('handles unicode characters in todo titles', () => {
      input.value = 'Buy 🥛 milk (日本語)';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy 🥛 milk (日本語)');
    });

    it('does not create todo when input is only newlines', () => {
      input.value = '\n\n\n';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('still clears input and re-renders if store returns falsy value', () => {
      input.value = 'Buy milk';
      mockTodoStoreCreate.mockReturnValue(null);

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(input.value).toBe('');
      expect(mockRenderTodoList).toHaveBeenCalledTimes(1);
    });
  });
});

describe('add-todo-submit-handler validation error tests', () => {
  let form;
  let input;
  let todoListContainer;

  beforeEach(() => {
    mockTodoStoreCreate.mockClear();
    mockRenderTodoList.mockClear();

    form = document.createElement('form');
    form.setAttribute('data-testid', 'add-todo-form');

    input = document.createElement('input');
    input.setAttribute('data-testid', 'todo-title-input');

    form.appendChild(input);

    todoListContainer = document.createElement('div');
    todoListContainer.setAttribute('data-testid', 'todo-list');

    document.body.appendChild(form);
    document.body.appendChild(todoListContainer);
  });

  afterEach(() => {
    if (form && form.parentNode) form.parentNode.removeChild(form);
    if (todoListContainer && todoListContainer.parentNode) {
      todoListContainer.parentNode.removeChild(todoListContainer);
    }
  });

  describe('Validation error display', () => {
    it('shows validation error when submitting empty input', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      const errorElement = document.querySelector('[data-testid="validation-error"]');
      expect(errorElement).not.toBeNull();
      expect(errorElement.textContent.length).toBeGreaterThan(0);
    });

    it('error message is visible to user', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      const errorElement = document.querySelector('[data-testid="validation-error"]');
      expect(errorElement.style.display).not.toBe('none');
    });

    it('clears validation error on subsequent valid submission', () => {
      // First submit empty to trigger error
      input.value = '';
      let submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      // Then submit valid
      input.value = 'Buy milk';
      submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      const errorElement = document.querySelector('[data-testid="validation-error"]');
      expect(errorElement).toBeNull();
    });
  });

  describe('No todo created on validation failure', () => {
    it('store create is never called when input is empty string', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('store create is not called for whitespace-only input', () => {
      input.value = '     ';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('store create is not called for tab/newline only input', () => {
      input.value = '\t\n\t';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('no re-render triggered when validation fails', () => {
      input.value = '';

      const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
      handleAddTodoSubmit(submitEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockRenderTodoList).not.toHaveBeenCalled();
    });
  });
});

describe('add-todo-submit-handler Enter key tests', () => {
  let input;
  let todoListContainer;

  beforeEach(() => {
    mockTodoStoreCreate.mockClear();
    mockRenderTodoList.mockClear();

    input = document.createElement('input');
    input.setAttribute('data-testid', 'todo-title-input');

    todoListContainer = document.createElement('div');
    todoListContainer.setAttribute('data-testid', 'todo-list');

    document.body.appendChild(input);
    document.body.appendChild(todoListContainer);
  });

  afterEach(() => {
    if (input && input.parentNode) input.parentNode.removeChild(input);
    if (todoListContainer && todoListContainer.parentNode) {
      todoListContainer.parentNode.removeChild(todoListContainer);
    }
  });

  describe('Enter key triggers same behavior as Add button', () => {
    it('Enter key calls todo-store-create with same arguments as button click', () => {
      input.value = 'Buy milk';

      // Simulate Enter key
      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledTimes(1);
      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });

    it('Enter key clears input same as button click', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(input.value).toBe('');
    });

    it('Enter key triggers re-render same as button click', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockRenderTodoList).toHaveBeenCalledTimes(1);
    });

    it('Enter with empty input shows validation error same as button', () => {
      input.value = '';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      const errorElement = document.querySelector('[data-testid="validation-error"]');
      expect(errorElement).not.toBeNull();
    });

    it('Enter with empty input does not call create same as button', () => {
      input.value = '';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).not.toHaveBeenCalled();
    });

    it('Enter key trims input same as button click', () => {
      input.value = '  Buy milk  ';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'Enter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });
  });

  describe('Key filtering', () => {
    it('does not submit on keys other than Enter', () => {
      const keysToTest = ['Escape', 'Tab', 'Space', 'ArrowDown', 'a', '1'];

      keysToTest.forEach(key => {
        mockTodoStoreCreate.mockClear();
        input.value = 'Buy milk';

        const keydownEvent = new KeyboardEvent('keydown', {
          key: key,
          bubbles: true,
          cancelable: true
        });
        handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

        expect(mockTodoStoreCreate).not.toHaveBeenCalled();
        expect(input.value).toBe('Buy milk'); // Unchanged
      });
    });

    it('handles NumpadEnter same as Enter', () => {
      input.value = 'Buy milk';

      const keydownEvent = new KeyboardEvent('keydown', {
        key: 'NumpadEnter',
        bubbles: true,
        cancelable: true
      });
      handleAddTodoSubmit(keydownEvent, input, todoListContainer, mockTodoStoreCreate, mockRenderTodoList);

      expect(mockTodoStoreCreate).toHaveBeenCalledWith('Buy milk');
    });
  });
});
