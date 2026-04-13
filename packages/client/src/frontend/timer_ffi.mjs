// FFI for JavaScript timer functionality

export function setTimeoutEffect(dispatch, msg, delay) {
  setTimeout(() => {
    dispatch(msg);
  }, delay);
  return undefined;
}
