// FFI for making HTTP requests from Lustre frontend

/**
 * Create a new todo via POST /api/todos
 * @param {string} title - The todo title
 * @param {string} description - The todo description (can be empty)
 * @param {Function} dispatch - Lustre dispatch function
 */
export function createTodo(title, description, dispatch) {
  const url = `http://localhost:3000/api/todos`;

  // Build request body - only include description if non-empty
  const body = { title };
  if (description && description.trim()) {
    body.description = description;
  }

  fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  })
    .then(async (response) => {
      const data = await response.json();

      if (response.ok) {
        // Success - dispatch SubmitSuccess with the created todo
        dispatch({
          type: "SubmitSuccess",
          0: {
            id: data.id,
            title: data.title,
            description: data.description || "",
            priority: data.priority || "medium",
            completed: data.completed !== undefined ? data.completed : false,
            created_at: data.created_at ? Date.parse(data.created_at) : Date.now(),
            updated_at: data.updated_at ? Date.parse(data.updated_at) : Date.now(),
          },
        });
      } else if (response.status === 422) {
        // Validation error - extract error messages
        const errorMessage = extractErrorMessage(data);
        dispatch({
          type: "SubmitError",
          0: errorMessage,
        });
      } else {
        // Other errors
        dispatch({
          type: "SubmitError",
          0: data.message || `Error: ${response.status}`,
        });
      }
    })
    .catch((error) => {
      dispatch({
        type: "SubmitError",
        0: error.message || "Network error",
      });
    });
}

/**
 * Fetch all todos via GET /api/todos
 * @param {Function} dispatch - Lustre dispatch function
 */
export function fetchTodos(dispatch) {
  const url = `http://localhost:3000/api/todos`;

  fetch(url)
    .then(async (response) => {
      const data = await response.json();

      if (response.ok) {
        // Transform API response to Todo objects
        const todos = data.map((item) => ({
          id: item.id,
          title: item.title,
          description: item.description || "",
          priority: item.priority || "medium",
          completed: item.completed !== undefined ? item.completed : false,
          created_at: item.created_at ? Date.parse(item.created_at) : Date.now(),
          updated_at: item.updated_at ? Date.parse(item.updated_at) : Date.now(),
        }));

        dispatch({
          type: "TodosLoaded",
          0: todos,
        });
      } else {
        dispatch({
          type: "TodosLoadError",
          0: data.message || `Error: ${response.status}`,
        });
      }
    })
    .catch((error) => {
      dispatch({
        type: "TodosLoadError",
        0: error.message || "Network error",
      });
    });
}

/**
 * Extract error message from API error response
 * @param {Object} data - The error response data
 * @returns {string} - Error message to display
 */
function extractErrorMessage(data) {
  if (data.errors && Array.isArray(data.errors) && data.errors.length > 0) {
    // Join all error messages
    return data.errors.map((err) => err.message).join("; ");
  }
  if (data.message) {
    return data.message;
  }
  return "Validation failed";
}
