@external(erlang, "auth_crypto_ffi", "hash_password")
pub fn hash_password(password: String, salt: String) -> String

@external(erlang, "auth_crypto_ffi", "generate_salt")
pub fn generate_salt() -> String

@external(erlang, "auth_crypto_ffi", "hmac_sign")
pub fn hmac_sign(data: String, secret: String) -> String

@external(erlang, "auth_crypto_ffi", "generate_id")
pub fn generate_id() -> String

@external(erlang, "auth_crypto_ffi", "system_time_seconds")
pub fn system_time_seconds() -> Int
