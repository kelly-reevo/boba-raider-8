// Required data-testid attributes:
// - add-todo-form: The form element for creating todos
// - todo-title-input: Input field for todo title
// - todo-description-input: Input field for todo description
// - add-todo-submit-btn: Submit button for the form

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

describe('create-todo-form', () => {
  let form;
  let titleInput;
  let descriptionInput;

  beforeEach(() => {
    vi.clearAllMocks();

    // Setup DOM
    document.body.innerHTML = `
      <form data-testid="add-todo-form">
        <input data-testid="todo-title-input" name="title" type="text" />
        <input data-testid="todo-description-input" name="description" type="text" />
        <button data-testid="add-todo-submit-btn" type="submit">Add</button>
      </form>
    `;

    form = document.querySelector('[data-testid="add-todo-form"]');
    titleInput = document.querySelector('[data-testid="todo-title-input"]');
    descriptionInput = document.querySelector('[data-testid="todo-description-input"]');

    // Setup mock response
    mockCreateTodo.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ id: '1', title: 'Test Todo', description: 'Test Desc', priority: 'medium', completed: false })
    });

    // Initialize form handler
    initCreateTodoForm();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('calls http-client.createTodo with form values when submitted with valid data', async () => {
    // Arrange
    titleInput.value = 'Buy Milk';
    descriptionInput.value = 'Get from the store';

    // Act
    const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
    form.dispatchEvent(submitEvent);

    // Assert
    await new Promise(resolve => setTimeout(resolve, 0));
    expect(mockCreateTodo).toHaveBeenCalledWith({
      title: 'Buy Milk',
      description: 'Get from the store'
    });
  });
});
