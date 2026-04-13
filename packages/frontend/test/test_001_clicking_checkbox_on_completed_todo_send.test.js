// @ts-check
/**
 * Test: Checkbox click on completed todo sends correct PATCH request
 * Validates: Toggle correctly negates completed state from true to false
 */
import { test, expect, vi } from 'vitest';

test('clicking checkbox on completed todo sends PATCH with completed: false', async () => {
  // Setup: Create todo item element with completed state
  document.body.innerHTML = `
    <ul id="todo-list">
      <li data-id="todo-456" class="todo-item completed">
        <input type="checkbox" class="toggle" data-completed="true" checked>
        <span class="todo-title">Walk dog</span>
      </li>
    </ul>
  `;

  const mockFetch = vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => ({ id: 'todo-456', title: 'Walk dog', completed: false })
  });
  globalThis.fetch = mockFetch;

  // Simulate checkbox click (uncheck)
  const checkbox = document.querySelector('input.toggle');
  checkbox.click();

  // Wait for async handler
  await new Promise(resolve => setTimeout(resolve, 0));

  // Assert: PATCH called with completed: false
  expect(mockFetch).toHaveBeenCalledWith('/api/todos/todo-456', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed: false })
  });
});
