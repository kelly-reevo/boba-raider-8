// FFI for client-side HTTP requests

export function fetchTodos(url, callback) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      // data is expected to be an array of {id, title, completed} objects
      const todos = data.map(item => ({
        id: item.id,
        title: item.title,
        completed: item.completed
      }));
      callback({ ok: true, value: todos });
    })
    .catch(error => {
      callback({ ok: false, error: error.message });
    });
}
