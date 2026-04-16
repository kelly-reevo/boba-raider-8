// FFI module for tracking effect metadata in tests
// This provides a mutable store for effect inspection

let currentMeta = { tag: "none", id: undefined };

export function set_current_meta(meta) {
  currentMeta = { tag: meta.tag, id: meta[0] };
  return undefined;
}

export function get_current_meta() {
  // Return in Gleam Option format: [value] for Some, undefined for None
  if (currentMeta.id === undefined) {
    return [currentMeta.tag, undefined];
  } else {
    return [currentMeta.tag, currentMeta.id];
  }
}
