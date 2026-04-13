/// Store List FFI - JavaScript interop for HTTP requests

/**
 * Fetch stores from the API
 * @param {string} url - The API URL to fetch
 * @param {function} callback - Callback function with result
 */
export function fetchStores(url, callback) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      // Convert stores to Gleam format
      const stores = data.stores.map(store => ({
        id: store.id,
        name: store.name,
        city: store.city,
        drink_count: store.drink_count || 0
      }));

      // Call callback with Ok result
      callback({
        Ok: [[stores, data.total || 0]]
      });
    })
    .catch(error => {
      // Call callback with Error result
      callback({
        Error: [error.message || "Failed to fetch stores"]
      });
    });
}
