/// JavaScript FFI for form validation utilities

/**
 * Check if a string matches a regex pattern.
 * @param {string} pattern - The regex pattern
 * @param {string} input - The string to test
 * @returns {boolean} - True if matches
 */
export function regex_check(pattern, input) {
  try {
    const regex = new RegExp(pattern);
    return regex.test(input);
  } catch (e) {
    return false;
  }
}

/**
 * Make a POST request to the API.
 * @param {string} url - The API endpoint
 * @param {object} data - The request payload
 * @returns {Promise<Response>} - The fetch response
 */
export async function api_post(url, data) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });
  return response;
}

/**
 * Navigate to a new URL.
 * @param {string} url - The destination URL
 */
export function navigate(url) {
  window.history.pushState({}, '', url);
  window.dispatchEvent(new PopStateEvent('popstate'));
}
