import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/otp/actor
import shared.{type Todo, Todo}

/// Internal message types for the todo actor
pub type TodoMsg {
  Create(
    title: String,
    description: String,
    priority: String,
    reply_to: Subject(Result(Todo, String)),
  )
  Read(id: String, reply_to: Subject(Result(Todo, String)))
  Delete(id: String, reply_to: Subject(Result(Nil, String)))
  Shutdown
}

/// Public handle type for the todo actor
pub type TodoActor =
  Subject(TodoMsg)

/// Actor state: dictionary of id -> Todo
pub type State {
  State(todos: Dict(String, Todo))
}

/// Start the todo actor with an empty state
pub fn start() -> Result(TodoActor, String) {
  let initial_state = State(dict.new())

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start todo actor")
  }
}

/// Handle incoming messages
fn handle_message(state: State, msg: TodoMsg) {
  case msg {
    Create(title, description, priority, reply_to) -> {
      let id = generate_id()
      let created_at = current_timestamp_string()
      let new_todo = Todo(id:, title:, description:, priority:, completed: False, created_at:)
      let new_state = State(dict.insert(state.todos, id, new_todo))
      process.send(reply_to, Ok(new_todo))
      actor.continue(new_state)
    }

    Read(id, reply_to) -> {
      case dict.get(state.todos, id) {
        Ok(found_todo) -> {
          process.send(reply_to, Ok(found_todo))
          actor.continue(state)
        }
        Error(_) -> {
          process.send(reply_to, Error("not_found"))
          actor.continue(state)
        }
      }
    }

    Delete(id, reply_to) -> {
      case dict.has_key(state.todos, id) {
        True -> {
          let new_state = State(dict.delete(state.todos, id))
          process.send(reply_to, Ok(Nil))
          actor.continue(new_state)
        }
        False -> {
          process.send(reply_to, Error("not_found"))
          actor.continue(state)
        }
      }
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

/// Create a new todo with the given fields
pub fn create(
  actor_pid: TodoActor,
  title: String,
  description: String,
  priority: String,
) -> Result(Todo, String) {
  process.call(actor_pid, 5000, fn(reply_to) {
    Create(title:, description:, priority:, reply_to:)
  })
}

/// Read a todo by id, returns the todo or not_found error
pub fn read(actor_pid: TodoActor, id: String) -> Result(Todo, String) {
  process.call(actor_pid, 5000, fn(reply_to) { Read(id:, reply_to:) })
}

/// Delete a todo by id
pub fn delete(actor_pid: TodoActor, id: String) -> Result(Nil, String) {
  process.call(actor_pid, 5000, fn(reply_to) { Delete(id:, reply_to:) })
}

/// Shutdown the actor
pub fn shutdown(actor_pid: TodoActor) -> Nil {
  actor.send(actor_pid, Shutdown)
}

/// Generate a simple unique id
fn generate_id() -> String {
  let now = now_timestamp_millis()
  let random = int.to_string(generate_random())
  "todo-" <> int.to_string(now) <> "-" <> random
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn now_timestamp_millis() -> Int

/// Generate a random integer
@external(erlang, "erlang", "unique_integer")
fn generate_random() -> Int

/// ISO8601 timestamp for created_at
fn current_timestamp_string() -> String {
  // FFI function gets current time and formats it to ISO8601
  format_timestamp_now(0)
}

@external(erlang, "server_ffi", "format_timestamp_millis")
fn format_timestamp_now(_unused: Int) -> String
