/// User module (unit-2)
/// Simple in-memory user storage using ETS table

import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import shared.{type AppError, type User, NotFound, InternalError}

/// User actor message types
pub type UserMsg {
  GetUser(id: String, reply: process.Subject(Result(User, AppError)))
  GetUserByUsername(username: String, reply: process.Subject(Result(User, AppError)))
  CreateUser(username: String, reply: process.Subject(Result(User, AppError)))
  Shutdown
}

pub type UserActor =
  process.Subject(UserMsg)

/// In-memory state for users
pub type UserState {
  UserState(users: Dict(String, User), next_id: Int)
}

/// Initialize user actor with some seed data
fn initial_state() -> UserState {
  // Seed with a default user for testing
  let default_user = shared.User(
    id: "user_1",
    username: "testuser",
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )

  UserState(
    users: dict.from_list([#("user_1", default_user)]),
    next_id: 2,
  )
}

/// Start the user actor
pub fn start() -> Result(UserActor, String) {
  let handler = fn(state: UserState, msg: UserMsg) {
    case msg {
      GetUser(id, reply) -> {
        let result = case dict.get(state.users, id) {
          Ok(user) -> Ok(user)
          Error(_) -> Error(NotFound("user"))
        }
        process.send(reply, result)
        actor.continue(state)
      }

      GetUserByUsername(username, reply) -> {
        let result = dict.values(state.users)
          |> find_user_by_username(username)
        process.send(reply, result)
        actor.continue(state)
      }

      CreateUser(username, reply) -> {
        let id = "user_" <> int_to_string(state.next_id)
        let now = "2024-01-01T00:00:00Z"
        let user = shared.User(
          id: id,
          username: username,
          created_at: now,
          updated_at: now,
        )
        let new_users = dict.insert(state.users, id, user)
        let new_state = UserState(users: new_users, next_id: state.next_id + 1)
        process.send(reply, Ok(user))
        actor.continue(new_state)
      }

      Shutdown -> actor.stop()
    }
  }

  actor.new(initial_state())
  |> actor.on_message(handler)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start user actor" })
}

fn find_user_by_username(users: List(User), username: String) -> Result(User, AppError) {
  case users {
    [] -> Error(NotFound("user"))
    [user, ..rest] -> {
      case user.username == username {
        True -> Ok(user)
        False -> find_user_by_username(rest, username)
      }
    }
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    n if n < 0 -> "-" <> int_to_string(-n)
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      do_int_to_string(n / 10, digit <> acc)
    }
  }
}

/// Public API functions

pub fn get_user(actor: UserActor, id: String) -> Result(User, AppError) {
  let reply_subject = process.new_subject()
  process.send(actor, GetUser(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.unwrap(Error(InternalError("Timeout")))
}

pub fn stop(actor: UserActor) -> Nil {
  process.send(actor, Shutdown)
}
