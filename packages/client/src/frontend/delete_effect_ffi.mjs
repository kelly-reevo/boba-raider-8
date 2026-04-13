// FFI for delete todo effect - makes fetch request and handles response

export function delete_request(id, callback) {
  const url = `/api/todos/${id}`;

  fetch(url, {
    method: 'DELETE',
    headers: {
      'Accept': 'application/json'
    }
  })
    .then(response => {
      callback(response.status);
    })
    .catch(error => {
      // Network or other error - report as generic failure
      callback(0);
    });
}
