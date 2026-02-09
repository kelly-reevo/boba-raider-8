// FFI functions for the client

export function intToString(n) {
  return String(n);
}

// Example API call function
export function doFetch(url, onSuccess, onError) {
  fetch(url)
    .then(response => {
      if (!response.ok) throw new Error(response.statusText);
      return response.text();
    })
    .then(onSuccess)
    .catch(err => onError(err.message || 'Network error'));
}
