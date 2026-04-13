// FFI for drink detail effects - Browser fetch API wrapper

export function fetch_json(url) {
  return new Promise((resolve) => {
    fetch(url)
      .then(response => {
        const status = response.status;
        return response.text().then(body => {
          resolve({ ok: true, value: [status, body] });
        });
      })
      .catch(error => {
        resolve({ ok: false, error: error.message || "Network error" });
      });
  });
}
