/// JavaScript FFI for effects - API calls and string utilities

/**
 * Make a POST request to the API.
 * @param {string} url - The API endpoint
 * @param {string} payload - The JSON request body
 * @param {Function} callback - Callback function with Result
 */
export async function api_post(url, payload, callback) {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: payload,
    });

    const responseText = await response.text();

    if (!response.ok) {
      // Try to parse error message from JSON
      let errorMessage = 'Failed to create store';
      try {
        const errorJson = JSON.parse(responseText);
        errorMessage = errorJson.error || errorJson.message || errorMessage;
      } catch {
        errorMessage = response.statusText || errorMessage;
      }
      callback({
        type: 'Error',
        error: errorMessage,
      });
      return;
    }

    callback({
      type: 'Ok',
      value: responseText,
    });
  } catch (error) {
    // Network error or other exception
    const errorMessage = error.message?.toLowerCase().includes('network') ||
                        error.message?.toLowerCase().includes('fetch') ||
                        error.message?.toLowerCase().includes('failed')
      ? 'Network error: Please check your connection'
      : `Error: ${error.message}`;
    callback({
      type: 'Error',
      error: errorMessage,
    });
  }
}

/**
 * Replace all occurrences in string.
 */
export function replace_all(s, pattern, replacement) {
  return s.split(pattern).join(replacement);
}

/**
 * Check if string contains pattern.
 */
export function string_contains(s, pattern) {
  return s.includes(pattern);
}

/**
 * Find index of pattern in string.
 */
export function string_index_of(s, pattern) {
  return s.indexOf(pattern);
}

/**
 * Get substring from start to end.
 */
export function string_slice(s, start, length) {
  return s.slice(start, start + length);
}

/**
 * Get substring from start to end.
 */
export function string_slice_from(s, start) {
  return s.slice(start);
}

/**
 * Get string length.
 */
export function string_length(s) {
  return s.length;
}

/**
 * Trim leading whitespace.
 */
export function string_trim_left(s) {
  return s.trimStart();
}

/**
 * Check if string starts with prefix.
 */
export function string_starts_with(s, prefix) {
  return s.startsWith(prefix);
}

/**
 * Navigate to a new URL (SPA navigation).
 */
export function navigate(url) {
  window.history.pushState({}, '', url);
  // Dispatch a custom event for the router
  window.dispatchEvent(new PopStateEvent('popstate'));
}

/**
 * Get current pathname.
 */
export function get_pathname() {
  return window.location.pathname;
}
