export function submitRating(body, callback) {
  fetch("/api/ratings", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: body,
  })
    .then((response) => callback(response.status))
    .catch(() => callback(0));
}
