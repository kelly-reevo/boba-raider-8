// FFI module for tracking effect metadata in tests
// Simple string-based mutable store

let lastEffectTag = "none";
let lastEffectId = "";

export function set_last_effect_tag(tag) {
  lastEffectTag = tag;
  return undefined;
}

export function get_last_effect_tag() {
  return lastEffectTag;
}

export function set_last_effect_id(id) {
  lastEffectId = id;
  return undefined;
}

export function get_last_effect_id() {
  return lastEffectId;
}
