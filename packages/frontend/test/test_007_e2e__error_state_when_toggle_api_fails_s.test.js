// @ts-check
/**
 * E2E Test: API failure during toggle shows error and reverts checkbox
 * Validates: Complete error boundary contract from user perspective
 */
import { test, expect } from '@playwright/test';

test('API error during toggle shows error and reverts checkbox', async ({ page }) => {
  // Setup: Mock with incomplete todo, PATCH fails
  await page.route('/api/todos', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([
        { id: 'e2e-todo-3', title: 'Will Fail', completed: false, priority: 'high' }
      ])
    });
  });

  await page.route('/api/todos/e2e-todo-3', async (route) => {
    if (route.request().method() === 'PATCH') {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal server error' })
      });
    }
  });

  // Load page
  await page.goto('/');

  // Wait for todo
  const todoItem = page.locator('[data-id="e2e-todo-3"]');
  await expect(todoItem).toBeVisible();

  // Verify initial unchecked state
  const checkbox = todoItem.locator('input.toggle');
  await expect(checkbox).not.toBeChecked();

  // Attempt to check (will fail)
  await checkbox.click();

  // Wait briefly for error handling
  await page.waitForTimeout(100);

  // Verify checkbox reverted to unchecked
  await expect(checkbox).not.toBeChecked();

  // Verify error message is displayed
  const errorMessage = page.locator('#error-message, .error-message, [role="alert"]');
  await expect(errorMessage).toBeVisible();
  await expect(errorMessage).toContainText(/error|fail|unable/i);
});
