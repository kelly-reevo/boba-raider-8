// @ts-check
/**
 * Test: API error reverts checkbox to previous state and shows error
 * Validates: Error boundary contract - revert checkbox, display error, no DOM mutation
 */
import { test, expect, vi } from 'vitest';

test('failed PATCH reverts checkbox and shows error', async () => {
  // Setup: Create incomplete todo
  document.body.innerHTML = `
    <ul id="todo-list">
      <li data-id="todo-abc" class="todo-item">
        <input type="checkbox" class="toggle" data-completed="false">
        <span class="todo-title">Call mom</span>
      </li>
    </ul>
    <div id="error-message"></div>
  `;

  const mockFetch = vi.fn().mockRejectedValue(new Error('Network error'));
  globalThis.fetch = mockFetch;

  // Execute: Click checkbox (will fail)
  const checkbox = document.querySelector('input.toggle');
  const listItem = document.querySelector('.todo-item');
  const originalChecked = checkbox.checked;

  checkbox.click();

  // Wait for async handler and any error handling
  await new Promise(resolve => setTimeout(resolve, 10));

  // Assert: Checkbox reverted to original unchecked state
  expect(checkbox.checked).toBe(originalChecked);
  expect(checkbox.checked).toBe(false);

  // Assert: List item styling unchanged
  expect(listItem.classList.contains('completed')).toBe(false);

  // Assert: Error message displayed
  const errorContainer = document.getElementById('error-message');
  expect(errorContainer.textContent.length).toBeGreaterThan(0);
  expect(errorContainer.style.display).not.toBe('none');
});
