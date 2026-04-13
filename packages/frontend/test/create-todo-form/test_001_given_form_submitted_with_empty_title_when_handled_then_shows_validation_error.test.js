// Required data-testid attributes:
// - add-todo-form: The form element for creating todos
// - todo-title-input: Input field for todo title
// - todo-description-input: Input field for todo description
// - add-todo-submit-btn: Submit button for the form
// - title-validation-error: Inline error message for title validation

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock must be at top level for hoisting
const mockCreateTodo = vi.fn();

vi.mock('../../src/http_client.js', () => ({
  createTodo: (...args) => mockCreateTodo(...args)
}));

vi.mock('../../src/todo_list_renderer.js', () => ({
  refresh: vi.fn()
}));

import { initCreateTodoForm } from '../../src/create_todo_form.js';

describe('create-todo-form validation', () => {
  let form;
  let titleInput;
  let descriptionInput;

  beforeEach(() => {
    vi.clearAllMocks();

    document.body.innerHTML = `
      <form data-testid="add-todo-form">
        <input data-testid="todo-title-input" name="title" type="text" />
        <span data-testid="title-validation-error" style="display: none;"></span>
        <input data-testid="todo-description-input" name="description" type="text" />
        <button data-testid="add-todo-submit-btn" type="submit">Add</button>
      </form>
    `;

    form = document.querySelector('[data-testid="add-todo-form"]');
    titleInput = document.querySelector('[data-testid="todo-title-input"]');
    descriptionInput = document.querySelector('[data-testid="todo-description-input"]');

    initCreateTodoForm();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('shows inline validation error without calling API when title is empty', () => {
    // Arrange
    titleInput.value = '';
    descriptionInput.value = 'Some description';

    // Act
    const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
    form.dispatchEvent(submitEvent);

    // Assert
    expect(mockCreateTodo).not.toHaveBeenCalled();
    const errorEl = document.querySelector('[data-testid="title-validation-error"]');
    expect(errorEl.textContent).toContain('Title is required');
    expect(errorEl.style.display).not.toBe('none');
  });
});
