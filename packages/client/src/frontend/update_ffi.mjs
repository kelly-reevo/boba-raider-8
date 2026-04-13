/// JavaScript FFI for update functions

/**
 * Validate US phone number format.
 * Accepts formats like:
 * - 415-555-0123
 * - (415) 555-0123
 * - 415.555.0123
 * - 415 555 0123
 * - 4155550123
 * - +1 415-555-0123
 * - +1 (415) 555-0123
 * @param {string} phone - The phone number to validate
 * @returns {boolean} - True if valid
 */
export function validate_phone_format(phone) {
  if (!phone || phone.trim() === '') {
    return true; // Empty is valid (optional field)
  }

  // Remove all non-numeric characters except + at start
  const cleaned = phone.trim();

  // US phone number regex
  // Allows various formats with exactly 10 digits (or 11 with leading 1)
  const phoneRegex = /^(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})$/;

  if (!phoneRegex.test(cleaned)) {
    return false;
  }

  // Extract digits and validate count
  const digits = cleaned.replace(/\D/g, '');

  // Must be 10 digits, or 11 digits starting with 1
  if (digits.length === 10) {
    return true;
  }
  if (digits.length === 11 && digits[0] === '1') {
    return true;
  }

  return false;
}

/**
 * Get current page path.
 * @returns {string} - Current pathname
 */
export function get_current_path() {
  return window.location.pathname;
}

/**
 * Check if we're on the create store page.
 * @returns {boolean}
 */
export function is_create_store_page() {
  return window.location.pathname === '/stores/new';
}
