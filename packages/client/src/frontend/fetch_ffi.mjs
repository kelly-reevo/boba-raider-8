// FFI module for browser fetch API with callback pattern for Lustre

export function fetchWithCallback(url, method, body, callback) {
  const options = {
    method: method,
    headers: {
      'Content-Type': 'application/json',
    },
  };

  if (body !== null && body !== undefined) {
    options.body = body;
  }

  fetch(url, options)
    .then(async (response) => {
      const text = await response.text();
      callback({
        type: 'FetchSuccess',
        status: response.status,
        body: text,
      });
    })
    .catch((error) => {
      callback({
        type: 'FetchError',
        0: error.message || 'Network error',
      });
    });

  return undefined;
}
