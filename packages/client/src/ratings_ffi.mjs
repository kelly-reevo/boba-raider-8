export function fetchRatings(onSuccess, onError) {
  fetch("/api/ratings")
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return response.text();
    })
    .then((text) => onSuccess(text))
    .catch((err) => onError(err.message));
}
