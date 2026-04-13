// @ts-check
/**
 * Test: Successful API response updates UI without page reload
 * Validates: DOM updates (checkbox checked, completed class added) synchronously after fetch
 */
import { test, expect, vi } from 'vitest';

test('successful PATCH updates checkbox and styling without page reload', async () => {
  // Setup: Create incomplete todo
  document.body.innerHTML = `
    <ul id="todo-list">
      <li data-id="todo-789" class="todo-item">
        <input type="checkbox" class="toggle" data-completed="false">
        <span class="todo-title">Read book</span>
      </li>
    </ul>
    <div id="error-message"></div>
  `;

  let reloadCalled = false;
  const originalReload = globalThis.location?.reload;
  Object.defineProperty(globalThis, 'location', {
    value: { reload: () => { reloadCalled = true; } },
    writable: true,
    configurable: true
  });

  const mockFetch = vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => ({ id: 'todo-789', title: 'Read book', completed: true })
  });
  globalThis.fetch = mockFetch;

  // Execute: Click checkbox
  const checkbox = document.querySelector('input.toggle');
  const listItem = document.querySelector('.todo-item');
  checkbox.click();

  // Wait for async handler
  await new Promise(resolve => setTimeout(resolve, 0));

  // Assert: UI updated without reload
  expect(reloadCalled).toBe(false);
  expect(checkbox.checked).toBe(true);
  expect(listItem.classList.contains('completed')).toBe(true);
  expect(listItem.querySelector('.todo-title').classList.contains('strikethrough') ||
         listItem.classList.contains('completed')).toBe(true);

  // Cleanup
  if (originalReload) {
    Object.defineProperty(globalThis, 'location', {
      value: { reload: originalReload },
      writable: true,
      configurable: true
    });
  }
});
