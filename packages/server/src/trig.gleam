/// Math utilities - FFI wrapper for Erlang math functions

@external(erlang, "trig_ffi", "sin")
pub fn sin(x: Float) -> Float

@external(erlang, "trig_ffi", "cos")
pub fn cos(x: Float) -> Float

@external(erlang, "trig_ffi", "asin")
pub fn asin(x: Float) -> Float

@external(erlang, "trig_ffi", "pi")
pub fn pi() -> Float

@external(erlang, "trig_ffi", "sqrt")
pub fn sqrt(x: Float) -> Float
