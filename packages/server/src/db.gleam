import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/result
import gleam/string
import simplifile
import sqlight

pub type DbError {
  ConnectionError(String)
  MigrationError(String)
  QueryError(String)
}

pub type Connection {
  Connection(conn: sqlight.Connection)
}

/// Convert sqlight error to string
fn sqlight_error_to_string(err: sqlight.Error) -> String {
  let sqlight.SqlightError(_code, message, _offset) = err
  "SQL error [" <> message <> "]"
}

/// Open a database connection
pub fn open(path: String) -> Result(Connection, DbError) {
  case sqlight.open(path) {
    Ok(conn) -> Ok(Connection(conn))
    Error(err) -> Error(ConnectionError(sqlight_error_to_string(err)))
  }
}

/// Close a database connection
pub fn close(db: Connection) -> Nil {
  let _ = sqlight.close(db.conn)
  Nil
}

/// Initialize migrations table
fn init_migrations_table(db: Connection) -> Result(Nil, DbError) {
  let sql = "CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )"

  case sqlight.exec(sql, db.conn) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(MigrationError(sqlight_error_to_string(err)))
  }
}

/// Get list of applied migrations
fn get_applied_migrations(db: Connection) -> Result(List(String), DbError) {
  let sql = "SELECT version FROM schema_migrations ORDER BY version"

  // Decoder for a single row: extract the version string from the first column
  let row_decoder: Decoder(String) = decode.at([0], decode.string)

  case sqlight.query(sql, db.conn, [], row_decoder) {
    Ok(rows) -> Ok(rows)
    Error(err) -> Error(MigrationError(sqlight_error_to_string(err)))
  }
}

/// Record a migration as applied
fn record_migration(db: Connection, version: String) -> Result(Nil, DbError) {
  let sql = "INSERT INTO schema_migrations (version) VALUES (?)"

  let row_decoder: Decoder(Int) = decode.int

  case sqlight.query(sql, db.conn, [sqlight.text(version)], row_decoder) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(MigrationError(sqlight_error_to_string(err)))
  }
}

/// Check if a version is in the list of applied migrations
fn is_applied(applied: List(String), version: String) -> Bool {
  list.any(applied, fn(v) { v == version })
}

/// Run all pending migrations
pub fn migrate(db: Connection, migrations_dir: String) -> Result(Nil, DbError) {
  // Ensure migrations table exists
  use _ <- result.try(init_migrations_table(db))

  // Get already applied migrations
  use applied <- result.try(get_applied_migrations(db))

  // Read migration files
  use files <- result.try(
    simplifile.get_files(migrations_dir)
    |> result.map_error(fn(err) {
      MigrationError("Failed to read migrations dir: " <> simplifile.describe_error(err))
    }),
  )

  // Filter to SQL files, sort by version
  let migration_files =
    files
    |> list.filter(string.ends_with(_, ".sql"))
    |> list.sort(fn(a, b) {
      let va = extract_version(a)
      let vb = extract_version(b)
      string.compare(va, vb)
    })

  // Apply pending migrations
  list.try_each(migration_files, fn(filepath) {
    let version = extract_version(filepath)

    case is_applied(applied, version) {
      True -> Ok(Nil)
      False -> {
        use sql <- result.try(
          simplifile.read(filepath)
          |> result.map_error(fn(err) {
            MigrationError("Failed to read " <> filepath <> ": " <> simplifile.describe_error(err))
          }),
        )

        use _ <- result.try(
          sqlight.exec(sql, db.conn)
          |> result.map_error(fn(err) {
            MigrationError("Migration " <> version <> " failed: " <> sqlight_error_to_string(err))
          }),
        )

        record_migration(db, version)
      }
    }
  })
}

/// Extract version number from migration filename (e.g., "001_create_users.sql" -> "001")
fn extract_version(filename: String) -> String {
  filename
  |> string.split("_")
  |> list.first()
  |> result.unwrap("0")
}
