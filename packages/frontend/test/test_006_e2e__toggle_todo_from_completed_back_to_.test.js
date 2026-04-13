// @ts-check
/**
 * E2E Test: User unchecks a completed todo
 * Validates: Toggle from completed to incomplete propagates correctly
 */
import { test, expect } from '@playwright/test';

test('user unchecks completed todo', async ({ page }) => {
  // Setup: Mock with completed todo
  await page.route('/api/todos', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 'e2e-todo-2', title: 'Already Done', completed: true, priority: 'low' }
      ])
    });
  });

  await page.route('/api/todos/e2e-todo-2', async (route) => {
    if (route.request().method() === 'PATCH') {
      const body = await route.request().postDataJSON();
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'e2e-todo-2',
          title: 'Already Done',
          completed: body.completed,
          priority: 'low'
        })
      });
    }
  });

  // Load page
  await page.goto('/');

  // Wait for todo
  const todoItem = page.locator('[data-id="e2e-todo-2"]');
  await expect(todoItem).toBeVisible();

  // Verify initial state: completed
  const checkbox = todoItem.locator('input.toggle');
  await expect(checkbox).toBeChecked();
  await expect(todoItem).toHaveClass(/completed/);

  // Click to uncheck
  await checkbox.click();

  // Verify checkbox unchecked
  await expect(checkbox).not.toBeChecked();

  // Verify completed class removed
  await expect(todoItem).not.toHaveClass(/completed/);
});
