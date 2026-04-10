import gleam/dynamic

pub type Connection {
  Connection(ref: dynamic.Dynamic)
}

@external(erlang, "database_ffi", "connect")
fn ffi_connect(url: String) -> Result(dynamic.Dynamic, String)

@external(erlang, "database_ffi", "disconnect")
fn ffi_disconnect(conn: dynamic.Dynamic) -> Nil

@external(erlang, "database_ffi", "execute")
fn ffi_execute(
  conn: dynamic.Dynamic,
  sql: String,
  params: List(dynamic.Dynamic),
) -> Result(List(List(String)), String)

pub fn connect(database_url: String) -> Result(Connection, String) {
  case ffi_connect(database_url) {
    Ok(ref) -> Ok(Connection(ref: ref))
    Error(e) -> Error(e)
  }
}

pub fn disconnect(conn: Connection) -> Nil {
  ffi_disconnect(conn.ref)
}

pub fn execute(
  conn: Connection,
  sql: String,
  params: List(dynamic.Dynamic),
) -> Result(List(List(String)), String) {
  ffi_execute(conn.ref, sql, params)
}

pub fn execute_simple(
  conn: Connection,
  sql: String,
) -> Result(List(List(String)), String) {
  ffi_execute(conn.ref, sql, [])
}
