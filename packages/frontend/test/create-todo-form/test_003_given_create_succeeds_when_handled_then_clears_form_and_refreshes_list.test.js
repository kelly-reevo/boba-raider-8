// Required data-testid attributes:
// - add-todo-form: The form element for creating todos
// - todo-title-input: Input field for todo title
// - todo-description-input: Input field for todo description
// - add-todo-submit-btn: Submit button for the form

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock must be at top level for hoisting
const mockCreateTodo = vi.fn();
const mockRefreshList = vi.fn();

vi.mock('../../src/http_client.js', () => ({
  createTodo: (...args) => mockCreateTodo(...args)
}));

vi.mock('../../src/todo_list_renderer.js', () => ({
  refresh: (...args) => mockRefreshList(...args)
}));

import { initCreateTodoForm } from '../../src/create_todo_form.js';

describe('create-todo-form success handling', () => {
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
      <ul data-testid="todo-list"></ul>
    `;

    mockCreateTodo.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ id: '1', title: 'New Todo', description: 'New Desc', priority: 'medium', completed: false })
    });

    form = document.querySelector('[data-testid="add-todo-form"]');
    titleInput = document.querySelector('[data-testid="todo-title-input"]');
    descriptionInput = document.querySelector('[data-testid="todo-description-input"]');

    initCreateTodoForm();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('clears form inputs and refreshes list on successful create', async () => {
    // Arrange
    titleInput.value = 'New Todo';
    descriptionInput.value = 'New Description';

    // Act
    const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
    form.dispatchEvent(submitEvent);

    // Assert
    await new Promise(resolve => setTimeout(resolve, 0));
    expect(titleInput.value).toBe('');
    expect(descriptionInput.value).toBe('');
    expect(mockRefreshList).toHaveBeenCalled();
  });
});
