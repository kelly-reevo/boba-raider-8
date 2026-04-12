// FFI helpers for JavaScript target

export function intToString(n) {
  return String(n);
}

// Delete todo via fetch API
export function deleteTodo(url, callback) {
  fetch(url, { method: 'DELETE' })
    .then(response => {
      if (response.ok || response.status === 204) {
        callback(true);
      } else {
        callback(false);
      }
    })
    .catch(() => {
      callback(false);
    });
}
