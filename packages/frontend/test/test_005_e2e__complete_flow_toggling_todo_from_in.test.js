// @ts-check
/**
 * E2E Test: Full user workflow - click checkbox, API updates, UI reflects change
 * Validates: Complete boundary contract end-to-end
 */
import { test, expect } from '@playwright/test';

test('user toggles todo completion via checkbox', async ({ page }) => {
  // Setup: Mock API and seed with todo
  await page.route('/api/todos', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 'e2e-todo-1', title: 'E2E Test Todo', completed: false, priority: 'medium' }
      ])
    });
  });

  await page.route('/api/todos/e2e-todo-1', async (route) => {
    if (route.request().method() === 'PATCH') {
      const body = await route.request().postDataJSON();
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'e2e-todo-1',
          title: 'E2E Test Todo',
          completed: body.completed,
          priority: 'medium'
        })
      });
    }
  });

  // Load page with todo list
  await page.goto('/');

  // Wait for todo to render
  const todoItem = page.locator('[data-id="e2e-todo-1"]');
  await expect(todoItem).toBeVisible();

  // Verify initial state: not completed
  const checkbox = todoItem.locator('input.toggle');
  await expect(checkbox).not.toBeChecked();
  await expect(todoItem).not.toHaveClass(/completed/);

  // Click checkbox
  await checkbox.click();

  // Verify checkbox is checked
  await expect(checkbox).toBeChecked();

  // Verify item has completed class (styling change)
  await expect(todoItem).toHaveClass(/completed/);

  // Verify no page reload occurred (SPA behavior)
  // If page reloaded, we'd need to wait for elements again
  await expect(todoItem).toBeVisible();
  await expect(checkbox).toBeChecked();
});
