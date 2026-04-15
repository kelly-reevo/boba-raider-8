/**
 * Todo List Container Component
 * Renders and re-renders todo items based on current filter
 */

import { getFilteredTodos } from './todo_filter_logic.js';

/**
 * Manages the todo list container rendering
 */
export class TodoListContainer {
  constructor(containerSelector) {
    this.container = document.querySelector(containerSelector);
    this.todos = [];
  }

  /**
   * Set the full list of todos
   * @param {Array} todos - Array of todo objects
   */
  setTodos(todos) {
    this.todos = todos;
  }

  /**
   * Render the list based on current filter
   */
  render() {
    if (!this.container) return;

    const filteredTodos = getFilteredTodos(this.todos);

    // Clear existing content
    this.container.innerHTML = '';

    // Render filtered items
    filteredTodos.forEach(todo => {
      const todoElement = this.createTodoElement(todo);
      this.container.appendChild(todoElement);
    });
  }

  /**
   * Create a todo item DOM element
   * @param {Object} todo - Todo object with id, title, completed properties
   * @returns {HTMLElement} The todo item element
   */
  createTodoElement(todo) {
    const div = document.createElement('div');
    div.setAttribute('data-testid', 'todo-item');
    div.setAttribute('data-completed', todo.completed.toString());
    div.setAttribute('data-id', todo.id);
    div.textContent = todo.title;
    return div;
  }

  /**
   * Clear the container
   */
  clear() {
    if (this.container) {
      this.container.innerHTML = '';
    }
  }
}

/**
 * Initialize todo list container
 * @param {string} containerSelector - CSS selector for the container
 * @returns {TodoListContainer} The initialized container instance
 */
export function initTodoListContainer(containerSelector) {
  return new TodoListContainer(containerSelector);
}
