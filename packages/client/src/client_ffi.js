// FFI for client-side JavaScript operations

import { TodosLoaded, Ok, Error } from "./client_ffi_gleam.js";

/**
 * Fetch todos from the API
 * @param {Object} req - Request object
 * @param {Function} dispatch - Dispatch function for messages
 */
export function fetchTodos(req, dispatch) {
  fetch('/api/todos')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .then(todos => {
      dispatch(TodosLoaded(new Ok(todos)));
    })
    .catch(err => {
      dispatch(TodosLoaded(new Error(err.message || 'Failed to fetch todos')));
    });
}
