export function get_json(url, on_success, on_error) {
  fetch(url)
    .then(response => {
      if (!response.ok) throw new Error("HTTP error " + response.status);
      return response.json();
    })
    .then(data => on_success(data))
    .catch(err => on_error(err.message));
}
