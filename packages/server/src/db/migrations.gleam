import gleam/int
import gleam/list
import gleam/result
import db/database.{type Connection}
import simplifile

pub type Migration {
  Migration(version: Int, name: String, up_sql: String, down_sql: String)
}

pub type MigrationError {
  MigrationReadError(String)
  MigrationExecutionError(String)
  MigrationVersionError(String)
}

fn read_migration_file(
  path: String,
  version: Int,
  name: String,
) -> Result(Migration, MigrationError) {
  let version_str = case version {
    1 -> "001"
    n -> int.to_string(n)
  }
  let up_path = path <> "/" <> version_str <> "_" <> name <> ".sql"
  let down_path = path <> "/" <> version_str <> "_" <> name <> "_down.sql"

  use up_sql <- result.try(
    simplifile.read(up_path)
    |> result.map_error(fn(_) {
      MigrationReadError("Failed to read migration: " <> up_path)
    }),
  )

  use down_sql <- result.try(
    simplifile.read(down_path)
    |> result.map_error(fn(_) {
      MigrationReadError("Failed to read down migration: " <> down_path)
    }),
  )

  Ok(Migration(version: version, name: name, up_sql: up_sql, down_sql: down_sql))
}

pub fn load_migrations(migrations_dir: String) -> List(Migration) {
  let migration_files = [
    #(1, "create_users_table"),
  ]

  list.filter_map(migration_files, fn(file) {
    let #(version, name) = file
    case read_migration_file(migrations_dir, version, name) {
      Ok(migration) -> Ok(migration)
      Error(_) -> Error(Nil)
    }
  })
}

fn ensure_migrations_table(conn: Connection) -> Result(Nil, MigrationError) {
  let sql = "
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      applied_at TIMESTAMP NOT NULL DEFAULT NOW()
    );
  "

  case database.execute_simple(conn, sql) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(MigrationExecutionError("Failed to create migrations table: " <> e))
  }
}

fn get_applied_versions(conn: Connection) -> List(Int) {
  let sql = "SELECT version FROM schema_migrations ORDER BY version;"

  case database.execute_simple(conn, sql) {
    Ok(rows) -> {
      list.filter_map(rows, fn(row) {
        case row {
          [version_str] -> int.parse(version_str)
          _ -> Error(Nil)
        }
      })
    }
    Error(_) -> []
  }
}

pub fn run_migrations(
  conn: Connection,
  migrations_dir: String,
) -> Result(List(Int), MigrationError) {
  use _ <- result.try(ensure_migrations_table(conn))

  let applied = get_applied_versions(conn)
  let migrations = load_migrations(migrations_dir)

  let pending =
    list.filter(migrations, fn(m) {
      !list.contains(applied, m.version)
    })
    |> list.sort(fn(a, b) { int.compare(a.version, b.version) })

  case pending {
    [] -> Ok([])
    _ -> {
      list.try_map(pending, fn(migration) {
        case database.execute_simple(conn, migration.up_sql) {
          Ok(_) -> {
            let insert_sql = "INSERT INTO schema_migrations (version, name) VALUES (" <> int.to_string(migration.version) <> ", '" <> migration.name <> "');"

            case database.execute_simple(conn, insert_sql) {
              Ok(_) -> Ok(migration.version)
              Error(e) -> Error(MigrationExecutionError("Failed to record migration " <> migration.name <> ": " <> e))
            }
          }
          Error(e) -> Error(MigrationExecutionError("Failed to run migration " <> migration.name <> ": " <> e))
        }
      })
    }
  }
}

pub fn rollback_migration(
  conn: Connection,
  version: Int,
  migrations_dir: String,
) -> Result(Nil, MigrationError) {
  use _ <- result.try(ensure_migrations_table(conn))

  let applied = get_applied_versions(conn)

  case list.contains(applied, version) {
    False -> Error(MigrationVersionError("Migration not applied"))
    True -> {
      let migrations = load_migrations(migrations_dir)
      case list.find(migrations, fn(m) { m.version == version }) {
        Ok(migration) -> {
          case database.execute_simple(conn, migration.down_sql) {
            Ok(_) -> {
              let delete_sql = "DELETE FROM schema_migrations WHERE version = " <> int.to_string(version) <> ";"

              case database.execute_simple(conn, delete_sql) {
                Ok(_) -> Ok(Nil)
                Error(e) -> Error(MigrationExecutionError("Failed to remove migration record: " <> e))
              }
            }
            Error(e) -> Error(MigrationExecutionError("Failed to run down migration: " <> e))
          }
        }
        Error(_) -> Error(MigrationVersionError("Migration file not found"))
      }
    }
  }
}

pub fn error_to_string(error: MigrationError) -> String {
  case error {
    MigrationReadError(msg) -> "Read error: " <> msg
    MigrationExecutionError(msg) -> "Execution error: " <> msg
    MigrationVersionError(msg) -> "Version error: " <> msg
  }
}
