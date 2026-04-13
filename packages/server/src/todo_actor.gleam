/// OTP Actor for in-memory todo storage
/// State format: Dict<String, Todo> where key is uuid, value is Todo record
/// Persists for the application lifetime

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/order
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string
import models/todo_item.{type Todo}

/// Filter options for listing todos
pub type Filter {
  All
  Completed(Bool)
}

/// Internal message types for the todo actor
pub type TodoMsg {
  Create(
    title: String,
    description: String,
    priority: String,
    reply_to: Subject(Result(Todo, String)),
  )
  Read(id: String, reply_to: Subject(Result(Todo, String)))
  Update(
    id: String,
    title: Option(String),
    description: Option(String),
    priority: Option(String),
    completed: Option(Bool),
    reply_to: Subject(Result(Todo, String)),
  )
  Delete(id: String, reply_to: Subject(Result(Nil, String)))
  GetAll(reply_to: Subject(Dict(String, Todo)))
  List(filter: Filter, reply_to: Subject(List(Todo)))
  GetById(id: String, reply_to: Subject(Option(Todo)))
  Toggle(id: String, reply_to: Subject(Result(Todo, String)))
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
      let now = now_timestamp_millis()
      let priority_val = todo_item.parse_priority(priority)
      // Store description as provided (empty string is valid)
      let description_val = Some(description)
      let new_todo = todo_item.Todo(
        id: id,
        title: title,
        description: description_val,
        priority: priority_val,
        completed: False,
        created_at: now,
        updated_at: now,
      )
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

    Update(id, title, description, priority, completed, reply_to) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let updated_title = case title {
            Some(t) -> t
            None -> existing.title
          }
          let updated_description = case description {
            Some(d) -> Some(d)
            None -> existing.description
          }
          let updated_priority = case priority {
            Some(p) -> todo_item.parse_priority(p)
            None -> existing.priority
          }
          let updated_completed = case completed {
            Some(c) -> c
            None -> existing.completed
          }
          let now = now_timestamp_millis()
          let updated = todo_item.Todo(
            ..existing,
            title: updated_title,
            description: updated_description,
            priority: updated_priority,
            completed: updated_completed,
            updated_at: now,
          )
          let new_state = State(dict.insert(state.todos, id, updated))
          process.send(reply_to, Ok(updated))
          actor.continue(new_state)
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

    GetAll(reply_to) -> {
      process.send(reply_to, state.todos)
      actor.continue(state)
    }

    List(filter, reply_to) -> {
      let all_todos = dict.values(state.todos)
      let filtered = case filter {
        All -> all_todos
        Completed(True) -> list.filter(all_todos, fn(t) { t.completed })
        Completed(False) -> list.filter(all_todos, fn(t) { !t.completed })
      }
      // Sort by created_at descending (newest first) - using int comparison for timestamps
      let sorted = list.sort(filtered, fn(a, b) {
        case int.compare(a.created_at, b.created_at) {
          order.Lt -> order.Gt
          order.Eq -> order.Eq
          order.Gt -> order.Lt
        }
      })
      process.send(reply_to, sorted)
      actor.continue(state)
    }

    GetById(id, reply_to) -> {
      process.send(reply_to, dict.get(state.todos, id) |> option.from_result)
      actor.continue(state)
    }

    Toggle(id, reply_to) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let updated = todo_item.toggle(existing)
          let new_state = State(dict.insert(state.todos, id, updated))
          process.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
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

/// Public API: Create a new todo with the given fields
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

/// Public API: Read a todo by id, returns the todo or not_found error
pub fn read(actor_pid: TodoActor, id: String) -> Result(Todo, String) {
  process.call(actor_pid, 5000, fn(reply_to) { Read(id:, reply_to:) })
}

/// Public API: Update an existing todo with partial fields
pub fn update(
  actor_pid: TodoActor,
  id: String,
  title: Option(String),
  description: Option(String),
  priority: Option(String),
  completed: Option(Bool),
) -> Result(Todo, String) {
  process.call(actor_pid, 5000, fn(reply_to) {
    Update(id:, title:, description:, priority:, completed:, reply_to:)
  })
}

/// Public API: Delete a todo by id
pub fn delete(actor_pid: TodoActor, id: String) -> Result(Nil, String) {
  process.call(actor_pid, 5000, fn(reply_to) { Delete(id:, reply_to:) })
}

/// Public API: Get all todos as Dict
pub fn get_all(actor_pid: TodoActor) -> Dict(String, Todo) {
  process.call(actor_pid, 5000, fn(reply_to) { GetAll(reply_to:) })
}

/// Public API: List todos with optional filter, sorted by created_at descending
pub fn list(actor_pid: TodoActor, filter: Filter) -> List(Todo) {
  process.call(actor_pid, 5000, fn(reply_to) { List(filter:, reply_to:) })
}

/// Public API: Get todo by ID
pub fn get_by_id(actor_pid: TodoActor, id: String) -> Option(Todo) {
  process.call(actor_pid, 5000, fn(reply_to) { GetById(id:, reply_to:) })
}

/// Public API: Toggle todo completion
pub fn toggle(actor_pid: TodoActor, id: String) -> Result(Todo, String) {
  process.call(actor_pid, 5000, fn(reply_to) { Toggle(id:, reply_to:) })
}

/// Public API: Shutdown the actor
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
  format_timestamp_now(0)
}

@external(erlang, "server_ffi", "format_timestamp_millis")
fn format_timestamp_now(_unused: Int) -> String

