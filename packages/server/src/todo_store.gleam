// OTP Actor for maintaining in-memory todo state
// Holds Dict(String, Todo) and handles concurrent access safely

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Pid, type Subject}
import gleam/otp/actor.{type Next}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/result

// ============================================================================
// Public Types
// ============================================================================

/// Todo item representing a task
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    completed: Bool,
  )
}

// ============================================================================
// Actor State and Messages
// ============================================================================

/// Actor state: dictionary mapping id -> Todo
pub type State {
  State(todos: Dict(String, Todo))
}

/// Internal message protocol for the actor
pub type Message {
  Get(String, Subject(Result(Todo, Nil)))
  GetAll(Subject(Dict(String, Todo)))
  Put(Todo, Subject(Result(Nil, Nil)))
  Delete(String, Subject(Result(Nil, Nil)))
}

// ============================================================================
// FFI-based Registry for Pid -> Subject mapping
// ============================================================================

@external(erlang, "todo_store_ffi", "register_pid")
fn ffi_register_pid(pid: Pid, subject: Subject(Message)) -> Nil

@external(erlang, "todo_store_ffi", "lookup_subject")
fn ffi_lookup_subject(pid: Pid) -> Result(Subject(Message), Nil)

@external(erlang, "todo_store_ffi", "register_supervisor")
fn ffi_register_supervisor(sup: Pid, store_pid: Pid) -> Nil

@external(erlang, "todo_store_ffi", "lookup_supervisor")
fn ffi_lookup_supervisor(sup: Pid) -> Result(Pid, Nil)

fn register_pid(pid: Pid, subject: Subject(Message)) -> Nil {
  ffi_register_pid(pid, subject)
}

fn lookup_subject(pid: Pid) -> Result(Subject(Message), Nil) {
  ffi_lookup_subject(pid)
}

fn register_supervisor(sup: Pid, store_pid: Pid) -> Nil {
  ffi_register_supervisor(sup, store_pid)
}

fn lookup_supervisor(sup: Pid) -> Result(Pid, Nil) {
  ffi_lookup_supervisor(sup)
}

// ============================================================================
// Public API
// ============================================================================

/// Start an unsupervised actor instance
/// Returns: Result(Pid, Error) per boundary contract
pub fn start_link() -> Result(Pid, Nil) {
  let builder =
    actor.new(State(todos: dict.new()))
    |> actor.on_message(handle_message)

  case actor.start(builder) {
    Ok(started) -> {
      // Register the pid -> subject mapping in ETS table
      register_pid(started.pid, started.data)
      Ok(started.pid)
    }
    Error(_) -> Error(Nil)
  }
}

/// Start a supervised actor under a supervisor
/// Returns: Result(Supervisor, Nil)
pub fn start_supervised() -> Result(Pid, Nil) {
  // Track the store pid so we can link it to the supervisor
  let store_pid_ref = process.new_subject()

  // Create child specification for the actor using supervision.worker
  let child_spec = supervision.worker(fn() {
    let builder =
      actor.new(State(todos: dict.new()))
      |> actor.on_message(handle_message)

    case actor.start(builder) {
      Ok(started) -> {
        // Register the pid -> subject mapping
        register_pid(started.pid, started.data)
        // Send the pid back to the parent
        process.send(store_pid_ref, started.pid)
        Ok(started)
      }
      Error(e) -> Error(e)
    }
  })

  // Start supervisor with OneForOne strategy
  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(child_spec)
  |> supervisor.start()
  |> result.map(fn(sup_started) {
    // Wait for the store pid
    let store_pid = process.receive(store_pid_ref, 1000)
      |> result.unwrap(sup_started.pid)
    // Register the supervisor -> store pid mapping
    register_supervisor(sup_started.pid, store_pid)
    sup_started.pid
  })
  |> result.map_error(fn(_) { Nil })
}

/// Get the store actor PID from a supervisor
/// Returns: Result(Pid, Nil)
pub fn get_store_pid(sup: Pid) -> Result(Pid, Nil) {
  // Use the registry to lookup the store pid by supervisor
  lookup_supervisor(sup)
}

/// Get a single todo by id
/// Returns: Result(Todo, Nil)
pub fn get(pid: Pid, id: String) -> Result(Todo, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { Get(id, reply_to) })
      |> result.map_error(fn(_) { Nil })
    }
    Error(_) -> Error(Nil)
  }
}

/// Get all todos as a dictionary
/// Returns: Dict(String, Todo)
pub fn get_all(pid: Pid) -> Dict(String, Todo) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { GetAll(reply_to) })
    }
    Error(_) -> dict.new()
  }
}

/// Store a todo (insert or update)
/// Returns: Result(Nil, Nil)
pub fn put(pid: Pid, todo_item: Todo) -> Result(Nil, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { Put(todo_item, reply_to) })
      |> result.map_error(fn(_) { Nil })
    }
    Error(_) -> Error(Nil)
  }
}

/// Delete a todo by id
/// Returns: Result(Nil, Nil)
pub fn delete(pid: Pid, id: String) -> Result(Nil, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { Delete(id, reply_to) })
      |> result.map_error(fn(_) { Nil })
    }
    Error(_) -> Error(Nil)
  }
}

// ============================================================================
// Actor Message Handlers
// ============================================================================

/// Handle incoming messages - actor callback
fn handle_message(state: State, msg: Message) -> Next(State, Message) {
  case msg {
    Get(id, reply_to) -> {
      let result = dict.get(state.todos, id)
      process.send(reply_to, result)
      actor.continue(state)
    }

    GetAll(reply_to) -> {
      process.send(reply_to, state.todos)
      actor.continue(state)
    }

    Put(todo_item, reply_to) -> {
      let new_todos = dict.insert(state.todos, todo_item.id, todo_item)
      process.send(reply_to, Ok(Nil))
      actor.continue(State(todos: new_todos))
    }

    Delete(id, reply_to) -> {
      let new_todos = dict.delete(state.todos, id)
      // Always succeed (idempotent delete)
      process.send(reply_to, Ok(Nil))
      actor.continue(State(todos: new_todos))
    }
  }
}
