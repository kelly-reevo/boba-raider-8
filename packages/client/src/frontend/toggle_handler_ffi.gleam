/// FFI module for toggle handler JavaScript

/// Initialize toggle handlers on the document
@external(javascript, "./toggle_handler.js", "initToggleHandlers")
pub fn init() -> Nil
