export function do_fetch(url, on_ok, on_err) {
  fetch(url)
    .then((response) => {
      if (!response.ok) throw new Error("Server error: " + response.status);
      return response.json();
    })
    .then((data) => on_ok(data))
    .catch((err) => on_err(err.message || "Network error"));
}
