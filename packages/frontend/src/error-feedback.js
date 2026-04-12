/**
 * Error Feedback Module
 * Handles displaying user-friendly error messages for API failures.
 */

/**
 * Display user-friendly error message based on error type
 * @param {Error|Object} error - Error object from API client
 * @param {number} [error.status] - HTTP status code
 * @param {string} [error.statusText] - HTTP status text
 * @param {Object} [error.response] - Parsed error response body
 */
export function handleApiError(error) {
  // Network error (TypeError from fetch failures like "Failed to fetch")
  if (error instanceof TypeError || error.name === 'TypeError') {
    displayGlobalError('Unable to connect. Please check your connection.');
    return;
  }

  // Validation error (422)
  if (error.status === 422) {
    const errors = error.response?.errors;
    if (Array.isArray(errors) && errors.length > 0) {
      displayInlineErrors(errors);
      return;
    }
    // Malformed 422 response - fall through to generic error
  }

  // Server error (5xx) or any other error
  displayGlobalError('Something went wrong. Please try again.');
}

/**
 * Clear error messages
 * @param {string} [target] - 'global' for container, field name for inline, undefined for all
 */
export function clearError(target) {
  if (target === 'global' || target === undefined) {
    clearGlobalError();
  }

  if (target !== 'global') {
    if (target && target !== 'global') {
      clearFieldError(target);
    } else {
      clearAllFieldErrors();
    }
  }
}

/**
 * Display error in the global error container
 * @param {string} message - Error message to display
 */
function displayGlobalError(message) {
  const container = document.getElementById('error-container');
  if (container) {
    container.textContent = message;
    container.style.display = 'block';
  }
}

/**
 * Clear the global error container
 */
function clearGlobalError() {
  const container = document.getElementById('error-container');
  if (container) {
    container.textContent = '';
    container.style.display = 'none';
  }
}

/**
 * Display inline validation errors next to form fields
 * @param {Array<{field: string, message: string}>} errors - Array of field errors
 */
function displayInlineErrors(errors) {
  let hasDisplayedInline = false;

  for (const err of errors) {
    const fieldName = err.field;
    const message = err.message;

    // Find error element for this field
    const errorElement = document.querySelector(`[data-field="${fieldName}"].error-message`);
    if (errorElement) {
      errorElement.textContent = message;
      errorElement.style.display = 'block';
      hasDisplayedInline = true;
    } else {
      // Field not found - display in global container as fallback
      displayGlobalError(message);
    }
  }
}

/**
 * Clear error for a specific field
 * @param {string} fieldName - Name of the field to clear
 */
function clearFieldError(fieldName) {
  const errorElement = document.querySelector(`[data-field="${fieldName}"].error-message`);
  if (errorElement) {
    errorElement.textContent = '';
    errorElement.style.display = 'none';
  }
}

/**
 * Clear all field-level error messages
 */
function clearAllFieldErrors() {
  const errorElements = document.querySelectorAll('.error-message[data-field]');
  for (const el of errorElements) {
    el.textContent = '';
    el.style.display = 'none';
  }
}
