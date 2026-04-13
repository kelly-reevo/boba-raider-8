// FFI for HTTP fetch operations

// Helper to construct Gleam Result types
function ok(value) {
  return { ok: true, value: value };
}

function error(err) {
  return { ok: false, error: err };
}

// Helper to construct GotTodos message
function makeGotTodos(result) {
  return {
    __type: "GotTodos",
    0: result
  };
}

export function fetchTodos(dispatch) {
  fetch('/api/todos')
    .then(response => {
      if (!response.ok) {
        dispatch(makeGotTodos(error("Failed to load todos. Please try again.")));
      } else {
        return response.json().then(todos => {
          // Ensure todos is an array
          if (!Array.isArray(todos)) {
            dispatch(makeGotTodos(error("Invalid response format")));
            return;
          }
          dispatch(makeGotTodos(ok(todos)));
        });
      }
    })
    .catch(err => {
      dispatch(makeGotTodos(error("Network error. Please check your connection.")));
    });
}
