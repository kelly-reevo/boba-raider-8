// @ts-check
/**
 * Test: Checkbox click on incomplete todo sends correct PATCH request
 * Validates: Event handler extracts ID, negates current state, calls API
 */
import { test, expect, vi } from 'vitest';

test('clicking checkbox on incomplete todo sends PATCH with completed: true', async () => {
  // Setup: Create todo item element with incomplete state
  document.body.innerHTML = `
    <ul id="todo-list">
      <li data-id="todo-123" class="todo-item">
        <input type="checkbox" class="toggle" data-completed="false">
        <span class="todo-title">Buy milk</span>
      </li>
    </ul>
  `;

  const mockFetch = vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => ({ id: 'todo-123', title: 'Buy milk', completed: true })
  });
  globalThis.fetch = mockFetch;

  // Simulate checkbox click
  const checkbox = document.querySelector('input.toggle');
  checkbox.click();

  // Wait for async handler
  await new Promise(resolve => setTimeout(resolve, 0));

  // Assert: PATCH called with correct payload
  expect(mockFetch).toHaveBeenCalledWith('/api/todos/todo-123', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed: true })
  });
});
