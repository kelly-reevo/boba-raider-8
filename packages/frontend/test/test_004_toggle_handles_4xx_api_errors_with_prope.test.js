// @ts-check
/**
 * Test: 4xx error response reverts checkbox and displays error
 * Validates: Non-2xx status codes trigger error boundary behavior
 */
import { test, expect, vi } from 'vitest';

test('4xx error reverts checkbox and shows error', async () => {
  // Setup: Create completed todo
  document.body.innerHTML = `
    <ul id="todo-list">
      <li data-id="todo-def" class="todo-item completed">
        <input type="checkbox" class="toggle" data-completed="true" checked>
        <span class="todo-title">Grocery shopping</span>
      </li>
    </ul>
    <div id="error-message"></div>
  `;

  const mockFetch = vi.fn().mockResolvedValue({
    ok: false,
    status: 404,
    json: async () => ({ error: 'Todo not found' })
  });
  globalThis.fetch = mockFetch;

  // Execute: Click to uncheck (will fail with 404)
  const checkbox = document.querySelector('input.toggle');
  const listItem = document.querySelector('.todo-item');
  const originalChecked = checkbox.checked; // true

  checkbox.click();

  // Wait for async handler
  await new Promise(resolve => setTimeout(resolve, 0));

  // Assert: Response not ok, so error handler should revert
  expect(mockFetch).toHaveBeenCalled();

  // Assert: Checkbox should remain checked (reverted)
  expect(checkbox.checked).toBe(originalChecked);
  expect(checkbox.checked).toBe(true);

  // Assert: Error message displayed
  const errorContainer = document.getElementById('error-message');
  expect(errorContainer.textContent).toContain('error') ||
    expect(errorContainer.textContent.length).toBeGreaterThan(0);
});
