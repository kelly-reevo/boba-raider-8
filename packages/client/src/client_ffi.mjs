// FFI for client HTTP requests

export function fetchWithCallback(url, callback) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        callback(new Error(), `HTTP error: ${response.status}`);
        return;
      }
      return response.text();
    })
    .then(text => {
      if (text !== undefined) {
        callback(new Ok(), text);
      }
    })
    .catch(error => {
      callback(new Error(), error.message);
    });
}
