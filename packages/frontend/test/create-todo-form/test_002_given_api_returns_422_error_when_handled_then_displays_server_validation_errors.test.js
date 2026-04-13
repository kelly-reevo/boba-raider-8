// Required data-testid attributes:
// - add-todo-form: The form element for creating todos
// - todo-title-input: Input field for todo title
// - todo-description-input: Input field for todo description
// - add-todo-submit-btn: Submit button for the form
// - server-validation-error: Container for server-side validation errors

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

describe('create-todo-form server validation', () => {
  let form;
  let titleInput;
  let descriptionInput;

  beforeEach(() => {
    vi.clearAllMocks();

    document.body.innerHTML = `
      <form data-testid="add-todo-form">
        <input data-testid="todo-title-input" name="title" type="text" />
        <div data-testid="server-validation-error" style="display: none;"></div>
        <input data-testid="todo-description-input" name="description" type="text" />
        <button data-testid="add-todo-submit-btn" type="submit">Add</button>
      </form>
    `;

    mockCreateTodo.mockResolvedValue({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ errors: [{ field: 'title', message: 'Title must be unique' }] })
    });

    form = document.querySelector('[data-testid="add-todo-form"]');
    titleInput = document.querySelector('[data-testid="todo-title-input"]');
    descriptionInput = document.querySelector('[data-testid="todo-description-input"]');

    initCreateTodoForm();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('displays server validation errors when API returns 422', async () => {
    // Arrange
    titleInput.value = 'Duplicate Title';
    descriptionInput.value = 'Description';

    // Act
    const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
    form.dispatchEvent(submitEvent);

    // Assert
    await new Promise(resolve => setTimeout(resolve, 0));
    const errorEl = document.querySelector('[data-testid="server-validation-error"]');
    expect(errorEl.textContent).toContain('Title must be unique');
    expect(errorEl.style.display).not.toBe('none');
  });
});
