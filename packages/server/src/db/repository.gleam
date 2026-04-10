import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import db/database.{type Connection}

pub type User {
  User(
    id: String,
    email: String,
    username: String,
    password_hash: String,
    created_at: String,
    updated_at: String,
  )
}

fn user_from_row(row: List(String)) -> Result(User, String) {
  case row {
    [id, email, username, password_hash, created_at, updated_at] ->
      Ok(User(
        id: id,
        email: email,
        username: username,
        password_hash: password_hash,
        created_at: created_at,
        updated_at: updated_at,
      ))
    _ -> Error("Invalid user row format")
  }
}

pub fn create_user(
  conn: Connection,
  email: String,
  username: String,
  password_hash: String,
) -> Result(User, String) {
  let sql = "
    INSERT INTO users (email, username, password_hash)
    VALUES ('" <> email <> "', '" <> username <> "', '" <> password_hash <> "')
    RETURNING id, email, username, password_hash, created_at::text, updated_at::text;
  "

  case database.execute_simple(conn, sql) {
    Ok([row]) -> user_from_row(row)
    Ok(_) -> Error("Unexpected result from create user")
    Error(e) -> Error("Failed to create user: " <> e)
  }
}

pub fn get_user_by_id(conn: Connection, id: String) -> Result(Option(User), String) {
  let sql = "
    SELECT id, email, username, password_hash, created_at::text, updated_at::text
    FROM users
    WHERE id = '" <> id <> "';
  "

  case database.execute_simple(conn, sql) {
    Ok([row]) -> {
      case user_from_row(row) {
        Ok(user) -> Ok(Some(user))
        Error(e) -> Error(e)
      }
    }
    Ok([]) -> Ok(None)
    Ok(_) -> Error("Unexpected result from get user")
    Error(e) -> Error("Failed to get user: " <> e)
  }
}

pub fn get_user_by_email(conn: Connection, email: String) -> Result(Option(User), String) {
  let sql = "
    SELECT id, email, username, password_hash, created_at::text, updated_at::text
    FROM users
    WHERE email = '" <> email <> "';
  "

  case database.execute_simple(conn, sql) {
    Ok([row]) -> {
      case user_from_row(row) {
        Ok(user) -> Ok(Some(user))
        Error(e) -> Error(e)
      }
    }
    Ok([]) -> Ok(None)
    Ok(_) -> Error("Unexpected result from get user by email")
    Error(e) -> Error("Failed to get user by email: " <> e)
  }
}

pub fn get_user_by_username(conn: Connection, username: String) -> Result(Option(User), String) {
  let sql = "
    SELECT id, email, username, password_hash, created_at::text, updated_at::text
    FROM users
    WHERE username = '" <> username <> "';
  "

  case database.execute_simple(conn, sql) {
    Ok([row]) -> {
      case user_from_row(row) {
        Ok(user) -> Ok(Some(user))
        Error(e) -> Error(e)
      }
    }
    Ok([]) -> Ok(None)
    Ok(_) -> Error("Unexpected result from get user by username")
    Error(e) -> Error("Failed to get user by username: " <> e)
  }
}

pub fn update_user(
  conn: Connection,
  id: String,
  email: Option(String),
  username: Option(String),
  password_hash: Option(String),
) -> Result(User, String) {
  let updates =
    [
      #("email", email),
      #("username", username),
      #("password_hash", password_hash),
    ]
    |> list.filter(fn(field) {
      case field.1 {
        Some(_) -> True
        None -> False
      }
    })

  case updates {
    [] -> {
      case get_user_by_id(conn, id) {
        Ok(Some(user)) -> Ok(user)
        Ok(None) -> Error("User not found")
        Error(e) -> Error(e)
      }
    }
    _ -> {
      let set_clause =
        list.map(updates, fn(field) {
          case field.1 {
            Some(value) -> field.0 <> " = '" <> value <> "'"
            None -> ""
          }
        })
        |> list.filter(fn(s) { s != "" })
        |> string.join(", ")

      let sql = "
        UPDATE users
        SET " <> set_clause <> ", updated_at = NOW()
        WHERE id = '" <> id <> "'
        RETURNING id, email, username, password_hash, created_at::text, updated_at::text;
      "

      case database.execute_simple(conn, sql) {
        Ok([row]) -> user_from_row(row)
        Ok([]) -> Error("User not found")
        Ok(_) -> Error("Unexpected result from update user")
        Error(e) -> Error("Failed to update user: " <> e)
      }
    }
  }
}

pub fn delete_user(conn: Connection, id: String) -> Result(Nil, String) {
  let sql = "DELETE FROM users WHERE id = '" <> id <> "';"

  case database.execute_simple(conn, sql) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error("Failed to delete user: " <> e)
  }
}

pub fn user_to_json(user: User) -> json.Json {
  json.object([
    #("id", json.string(user.id)),
    #("email", json.string(user.email)),
    #("username", json.string(user.username)),
    #("created_at", json.string(user.created_at)),
    #("updated_at", json.string(user.updated_at)),
  ])
}
