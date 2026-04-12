// FFI module for client package - JavaScript interop

/**
 * Perform a fetch request and return the response text
 * @param {Object} req - Lustre request object
 * @param {Function} callback - Callback with Result<String, String>
 */
export function fetch_json(req, callback) {
  const method = req.method?.toString() || "GET";
  const path = req.path || "/";

  fetch(path, {
    method: method,
    headers: {
      "Accept": "application/json",
    },
  })
    .then(response => {
      if (!response.ok) {
        return response.text().then(text => {
          callback({
            type: "Error",
            message: text || `HTTP ${response.status}`,
          });
        });
      }
      return response.text();
    })
    .then(text => {
      if (typeof text === "string") {
        callback({
          type: "Ok",
          message: text,
        });
      }
    })
    .catch(error => {
      callback({
        type: "Error",
        message: error.message || "Network error",
      });
    });
}
