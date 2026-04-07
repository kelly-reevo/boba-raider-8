import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import shared.{type AppError, InternalError, InvalidInput, NotFound}
import user.{type User}

// --- Messages ---

pub type UserStoreMsg {
  Create(user: User, reply: Subject(Result(User, AppError)))
  GetById(id: String, reply: Subject(Result(User, AppError)))
  GetByUsername(username: String, reply: Subject(Result(User, AppError)))
  Update(user: User, reply: Subject(Result(User, AppError)))
  Delete(id: String, reply: Subject(Result(Nil, AppError)))
  ListAll(reply: Subject(List(User)))
}

pub type UserStore =
  Subject(UserStoreMsg)

// --- State ---

type State {
  State(
    users: Dict(String, User),
    username_index: Dict(String, String),
    email_index: Dict(String, String),
  )
}

fn empty_state() -> State {
  State(
    users: dict.new(),
    username_index: dict.new(),
    email_index: dict.new(),
  )
}

// --- Actor lifecycle ---

pub fn start() -> Result(UserStore, String) {
  case
    actor.new(empty_state())
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start user store")
  }
}

fn handle_message(
  state: State,
  msg: UserStoreMsg,
) -> actor.Next(State, UserStoreMsg) {
  case msg {
    Create(user, reply) -> {
      let #(new_state, result) = handle_create(state, user)
      process.send(reply, result)
      actor.continue(new_state)
    }
    GetById(id, reply) -> {
      process.send(reply, handle_get_by_id(state, id))
      actor.continue(state)
    }
    GetByUsername(username, reply) -> {
      process.send(reply, handle_get_by_username(state, username))
      actor.continue(state)
    }
    Update(user, reply) -> {
      let #(new_state, result) = handle_update(state, user)
      process.send(reply, result)
      actor.continue(new_state)
    }
    Delete(id, reply) -> {
      let #(new_state, result) = handle_delete(state, id)
      process.send(reply, result)
      actor.continue(new_state)
    }
    ListAll(reply) -> {
      process.send(reply, dict.values(state.users))
      actor.continue(state)
    }
  }
}

// --- Handlers ---

fn handle_create(
  state: State,
  user: User,
) -> #(State, Result(User, AppError)) {
  case dict.get(state.username_index, user.username) {
    Ok(_) -> #(state, Error(InvalidInput("Username already taken")))
    Error(_) ->
      case dict.get(state.email_index, user.email) {
        Ok(_) -> #(state, Error(InvalidInput("Email already registered")))
        Error(_) -> {
          let new_state =
            State(
              users: dict.insert(state.users, user.id, user),
              username_index: dict.insert(
                state.username_index,
                user.username,
                user.id,
              ),
              email_index: dict.insert(
                state.email_index,
                user.email,
                user.id,
              ),
            )
          #(new_state, Ok(user))
        }
      }
  }
}

fn handle_get_by_id(
  state: State,
  id: String,
) -> Result(User, AppError) {
  case dict.get(state.users, id) {
    Ok(user) -> Ok(user)
    Error(_) -> Error(NotFound("User not found"))
  }
}

fn handle_get_by_username(
  state: State,
  username: String,
) -> Result(User, AppError) {
  case dict.get(state.username_index, username) {
    Ok(id) ->
      case dict.get(state.users, id) {
        Ok(user) -> Ok(user)
        Error(_) -> Error(InternalError("Index inconsistency"))
      }
    Error(_) -> Error(NotFound("User not found"))
  }
}

fn handle_update(
  state: State,
  updated: User,
) -> #(State, Result(User, AppError)) {
  case dict.get(state.users, updated.id) {
    Error(_) -> #(state, Error(NotFound("User not found")))
    Ok(existing) -> {
      // Check username uniqueness if changed
      let username_conflict = case existing.username != updated.username {
        True ->
          case dict.get(state.username_index, updated.username) {
            Ok(_) -> True
            Error(_) -> False
          }
        False -> False
      }
      // Check email uniqueness if changed
      let email_conflict = case existing.email != updated.email {
        True ->
          case dict.get(state.email_index, updated.email) {
            Ok(_) -> True
            Error(_) -> False
          }
        False -> False
      }
      case username_conflict, email_conflict {
        True, _ -> #(state, Error(InvalidInput("Username already taken")))
        _, True -> #(state, Error(InvalidInput("Email already registered")))
        False, False -> {
          // Remove old index entries if changed, add new ones
          let username_idx = case existing.username != updated.username {
            True ->
              state.username_index
              |> dict.delete(existing.username)
              |> dict.insert(updated.username, updated.id)
            False -> state.username_index
          }
          let email_idx = case existing.email != updated.email {
            True ->
              state.email_index
              |> dict.delete(existing.email)
              |> dict.insert(updated.email, updated.id)
            False -> state.email_index
          }
          let new_state =
            State(
              users: dict.insert(state.users, updated.id, updated),
              username_index: username_idx,
              email_index: email_idx,
            )
          #(new_state, Ok(updated))
        }
      }
    }
  }
}

fn handle_delete(
  state: State,
  id: String,
) -> #(State, Result(Nil, AppError)) {
  case dict.get(state.users, id) {
    Error(_) -> #(state, Error(NotFound("User not found")))
    Ok(user) -> {
      let new_state =
        State(
          users: dict.delete(state.users, id),
          username_index: dict.delete(state.username_index, user.username),
          email_index: dict.delete(state.email_index, user.email),
        )
      #(new_state, Ok(Nil))
    }
  }
}

// --- Client API ---

const call_timeout = 5000

pub fn create(store: UserStore, user: User) -> Result(User, AppError) {
  process.call(store, call_timeout, Create(user, _))
}

pub fn get_by_id(store: UserStore, id: String) -> Result(User, AppError) {
  process.call(store, call_timeout, GetById(id, _))
}

pub fn get_by_username(
  store: UserStore,
  username: String,
) -> Result(User, AppError) {
  process.call(store, call_timeout, GetByUsername(username, _))
}

pub fn update(store: UserStore, user: User) -> Result(User, AppError) {
  process.call(store, call_timeout, Update(user, _))
}

pub fn delete(store: UserStore, id: String) -> Result(Nil, AppError) {
  process.call(store, call_timeout, Delete(id, _))
}

pub fn list_all(store: UserStore) -> List(User) {
  process.call(store, call_timeout, ListAll(_))
}
