// FFI for JavaScript fetch API

export function fetchTodos(url, callback) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        return response.text().then(text => {
          throw new Error(`Failed to fetch todos`);
        });
      }
      return response.json();
    })
    .then(data => {
      // Data should be an array of todo objects
      // Convert to Gleam-compatible format (array of tuples)
      const todos = data.map(item => ({
        id: item.id,
        title: item.title,
        description: item.description === null ? undefined : item.description,
        priority: item.priority,
        completed: item.completed,
        created_at: item.created_at,
        updated_at: item.updated_at
      }));
      callback({ Ok: todos });
    })
    .catch(error => {
      callback({ Error: error.message });
    });
}
