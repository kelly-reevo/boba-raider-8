/// FFI for getting the current origin

@external(javascript, "./origin_impl.mjs", "get_origin")
pub fn get_origin() -> String
