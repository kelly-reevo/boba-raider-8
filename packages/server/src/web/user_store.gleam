import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

/// User record representing stored user data (from unit-1)
pub type User {
  User(
    id: String,
    email: String,
    username: String,
    password_hash: String,
  )
}

/// Internal store messages
pub type StoreMsg {
  GetByEmail(String, Subject(Result(User, Nil)))
  Insert(User)
}

/// User store actor state
type StoreState {
  StoreState(users: Dict(String, User), email_index: Dict(String, String))
}

/// Actor handle for the user store
pub type UserStore =
  Subject(StoreMsg)

/// Start the user store actor
pub fn start() -> Result(UserStore, String) {
  let initial_state = StoreState(dict.new(), dict.new())

  let actor_result =
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()

  case actor_result {
    Ok(actor_data) -> Ok(actor_data.data)
    Error(_) -> Error("Failed to start user store")
  }
}

fn handle_message(
  state: StoreState,
  msg: StoreMsg,
) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    GetByEmail(email, reply_to) -> {
      let user = case dict.get(state.email_index, email) {
        Ok(id) ->
          case dict.get(state.users, id) {
            Ok(user) -> Ok(user)
            Error(_) -> Error(Nil)
          }
        Error(_) -> Error(Nil)
      }
      actor.send(reply_to, user)
      actor.continue(state)
    }

    Insert(user) -> {
      let new_users = dict.insert(state.users, user.id, user)
      let new_index = dict.insert(state.email_index, user.email, user.id)
      actor.continue(StoreState(new_users, new_index))
    }
  }
}

/// Find user by email
pub fn find_by_email(
  store: UserStore,
  email: String,
) -> Result(User, Nil) {
  let reply_subject = process.new_subject()
  actor.send(store, GetByEmail(email, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(user) -> user
    Error(_) -> Error(Nil)
  }
}

/// Verify password against hash (simple SHA256 comparison)
pub fn verify_password(password: String, hash: String) -> Bool {
  let generated_hash = hash_password(password)
  generated_hash == hash
}

/// Simple password hashing using SHA256 (use bcrypt/argon2 in production)
pub fn hash_password(password: String) -> String {
  let hashed = crypto.hash(crypto.Sha256, <<password:utf8>>)
  bit_array.base16_encode(hashed)
}

/// Add a user to the store (for testing/unit-1 integration)
pub fn add_user(store: UserStore, user: User) -> Nil {
  actor.send(store, Insert(user))
}
