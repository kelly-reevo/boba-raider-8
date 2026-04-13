// FFI for making HTTP requests from the browser

export function do_fetch(req, callback) {
  const url = req.url;
  const method = req.method;
  const headers = req.headers;
  const body = req.body;

  fetch(url, {
    method: method,
    headers: Object.fromEntries(headers),
    body: body,
  })
    .then(response => {
      if (!response.ok) {
        callback({ Ok: null, Error: null });
        return;
      }
      return response.text().then(text => {
        callback({ Ok: text, Error: null });
      });
    })
    .catch(() => {
      callback({ Ok: null, Error: null });
    });
}
