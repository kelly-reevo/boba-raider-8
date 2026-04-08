import auth/crypto
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type StoredUser {
  StoredUser(
    id: String,
    email: String,
    name: String,
    password_hash: String,
    salt: String,
  )
}

pub type UserStoreMsg {
  Register(
    email: String,
    name: String,
    password: String,
    reply: Subject(Result(StoredUser, String)),
  )
  Authenticate(
    email: String,
    password: String,
    reply: Subject(Result(StoredUser, String)),
  )
  GetById(id: String, reply: Subject(Result(StoredUser, String)))
}

pub type UserStore =
  Subject(UserStoreMsg)

type State {
  State(
    users_by_id: Dict(String, StoredUser),
    users_by_email: Dict(String, StoredUser),
  )
}

pub fn start() -> Result(UserStore, String) {
  let initial = State(users_by_id: dict.new(), users_by_email: dict.new())

  case
    actor.new(initial)
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
    Register(email, name, password, reply) ->
      handle_register(state, email, name, password, reply)
    Authenticate(email, password, reply) ->
      handle_authenticate(state, email, password, reply)
    GetById(id, reply) -> handle_get_by_id(state, id, reply)
  }
}

fn handle_register(
  state: State,
  email: String,
  name: String,
  password: String,
  reply: Subject(Result(StoredUser, String)),
) -> actor.Next(State, UserStoreMsg) {
  case dict.get(state.users_by_email, email) {
    Ok(_) -> {
      process.send(reply, Error("Email already registered"))
      actor.continue(state)
    }
    Error(Nil) -> {
      let id = crypto.generate_id()
      let salt = crypto.generate_salt()
      let password_hash = crypto.hash_password(password, salt)
      let user =
        StoredUser(
          id: id,
          email: email,
          name: name,
          password_hash: password_hash,
          salt: salt,
        )
      let new_state =
        State(
          users_by_id: dict.insert(state.users_by_id, id, user),
          users_by_email: dict.insert(state.users_by_email, email, user),
        )
      process.send(reply, Ok(user))
      actor.continue(new_state)
    }
  }
}

fn handle_authenticate(
  state: State,
  email: String,
  password: String,
  reply: Subject(Result(StoredUser, String)),
) -> actor.Next(State, UserStoreMsg) {
  case dict.get(state.users_by_email, email) {
    Ok(user) -> {
      let hash = crypto.hash_password(password, user.salt)
      case hash == user.password_hash {
        True -> process.send(reply, Ok(user))
        False -> process.send(reply, Error("Invalid credentials"))
      }
    }
    Error(Nil) -> process.send(reply, Error("Invalid credentials"))
  }
  actor.continue(state)
}

fn handle_get_by_id(
  state: State,
  id: String,
  reply: Subject(Result(StoredUser, String)),
) -> actor.Next(State, UserStoreMsg) {
  case dict.get(state.users_by_id, id) {
    Ok(user) -> process.send(reply, Ok(user))
    Error(Nil) -> process.send(reply, Error("User not found"))
  }
  actor.continue(state)
}
