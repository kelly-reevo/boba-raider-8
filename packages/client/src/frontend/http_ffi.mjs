// FFI for HTTP requests

export function doRequest(method, url, headers, body, expect, dispatch) {
  const init = {
    method: method,
    headers: Object.fromEntries(headers),
  };

  if (body && body !== "") {
    init.body = body;
  }

  fetch(url, init)
    .then(async (response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      // Handle different expect types
      if (expect.constructor.name === "ExpectAnything") {
        // For delete - don't parse body
        dispatch(expect[0]()); // success callback
        return;
      }

      const data = await response.json();

      if (expect.constructor.name === "ExpectJsonTodoList") {
        // Parse list of todos
        const todos = Array.isArray(data) ? data.map(item => ({
          id: String(item.id || ""),
          title: String(item.title || ""),
          completed: Boolean(item.completed)
        })) : [];
        dispatch(expect[0](todos));
      } else if (expect.constructor.name === "ExpectJsonTodo") {
        // Parse single todo
        const todo = {
          id: String(data.id || ""),
          title: String(data.title || ""),
          completed: Boolean(data.completed)
        };
        dispatch(expect[0](todo));
      }
    })
    .catch((error) => {
      // Error handling
      const errorMsg = error.message || "Network error";
      if (expect.constructor.name === "ExpectJsonTodoList") {
        dispatch(expect[1](errorMsg));
      } else if (expect.constructor.name === "ExpectJsonTodo") {
        dispatch(expect[1](errorMsg));
      } else {
        dispatch(expect[1](errorMsg));
      }
    });
}
