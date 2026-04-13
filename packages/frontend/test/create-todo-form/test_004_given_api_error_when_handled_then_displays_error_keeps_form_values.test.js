// Required data-testid attributes:
// - add-todo-form: The form element for creating todos
// - todo-title-input: Input field for todo title
// - todo-description-input: Input field for todo description
// - add-todo-submit-btn: Submit button for the form
// - create-todo-error-message: Error message container for API errors

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

describe('create-todo-form error handling', () => {
  let form;
  let titleInput;
  let descriptionInput;

  beforeEach(() => {
    vi.clearAllMocks();

    document.body.innerHTML = `
      <form data-testid="add-todo-form">
        <input data-testid="todo-title-input" name="title" type="text" />
        <input data-testid="todo-description-input" name="description" type="text" />
        <button data-testid="add-todo-submit-btn" type="submit">Add</button>
      </form>
      <div data-testid="create-todo-error-message" style="display: none;"></div>
    `;

    mockCreateTodo.mockRejectedValue(new Error('Network error'));

    form = document.querySelector('[data-testid="add-todo-form"]');
    titleInput = document.querySelector('[data-testid="todo-title-input"]');
    descriptionInput = document.querySelector('[data-testid="todo-description-input"]');

    initCreateTodoForm();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('displays error message and keeps form values on API error', async () => {
    // Arrange
    titleInput.value = 'Important Todo';
    descriptionInput.value = 'Important Description';

    // Act
    const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
    form.dispatchEvent(submitEvent);

    // Assert
    await new Promise(resolve => setTimeout(resolve, 0));
    const errorEl = document.querySelector('[data-testid="create-todo-error-message"]');
    expect(errorEl.textContent).toContain('Network error');
    expect(errorEl.style.display).not.toBe('none');
    expect(titleInput.value).toBe('Important Todo');
    expect(descriptionInput.value).toBe('Important Description');
  });
});
