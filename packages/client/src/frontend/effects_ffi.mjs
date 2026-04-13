// FFI for fetching todos from the browser

// Create a Gleam-style variant for FetchTodosSuccess
function createFetchTodosSuccess(todos) {
  return { type: "FetchTodosSuccess", 0: todos };
}

// Create a Gleam-style variant for FetchTodosError
function createFetchTodosError(error) {
  return { type: "FetchTodosError", 0: error };
}

export function fetchTodos(dispatch, url) {
  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      // Convert JSON array to format expected by Gleam
      const todos = data.map(item => [
        item.id || "",
        item.title || "",
        item.description || "",
        item.priority || "medium",
        !!item.completed,
        item.created_at || 0,
        item.updated_at || 0
      ]);
      dispatch(createFetchTodosSuccess(todos));
    })
    .catch(error => {
      dispatch(createFetchTodosError(error.message));
    });
}
