// OTP Actor for maintaining in-memory todo state with CRUD operations
// Holds Dict(String, Todo) and handles concurrent access safely

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Pid, type Subject}
import gleam/option.{type Option}
import gleam/otp/actor.{type Next}
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import gleam/result
import gleam/string
import shared.{type Todo, type UpdateTodoInput, Todo}

// ============================================================================
// Public Types
// ============================================================================

/// Store reference type - wraps the actor subject
pub opaque type Store {
  Store(subject: Subject(Message))
}

/// Actor state: dictionary mapping id -> Todo, plus id counter
pub type State {
  State(todos: Dict(String, Todo), next_id: Int)
}

/// Internal message protocol for the actor
pub type Message {
  // CRUD operations
  CreateTodo(
    title: String,
    description: String,
    reply_to: Subject(Result(Todo, String)),
  )
  GetTodo(id: String, reply_to: Subject(Option(Todo)))
  GetAllTodos(reply_to: Subject(List(Todo)))
  UpdateTodo(
    id: String,
    input: UpdateTodoInput,
    reply_to: Subject(Result(Todo, String)),
  )
  DeleteTodo(id: String, reply_to: Subject(Result(Nil, String)))
  // Legacy support for raw Pid-based operations
  GetRaw(String, Subject(Result(Todo, Nil)))
  GetAllRaw(Subject(Dict(String, Todo)))
  PutRaw(Todo, Subject(Result(Nil, Nil)))
  DeleteRaw(String, Subject(Result(Nil, Nil)))
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
// Public API - Modern CRUD Interface
// ============================================================================

/// Start the todo store actor (modern interface)
/// Returns: Result(Store, String)
pub fn start() -> Result(Store, String) {
  let initial_state = State(todos: dict.new(), next_id: 1)

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> {
      // Register the pid -> subject mapping in ETS table
      register_pid(started.pid, started.data)
      Ok(Store(started.data))
    }
    Error(_) -> Error("Failed to start todo store actor")
  }
}

/// Create a new todo
/// Boundary: create_todo(title: String, description: String) -> Result(Todo, String)
pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, String) {
  process.call(store.subject, 5000, CreateTodo(title, description, _))
}

/// Get a single todo by ID
/// Boundary: get_todo(store, id: String) -> Option(Todo)
pub fn get_todo(store: Store, id: String) -> Option(Todo) {
  process.call(store.subject, 5000, GetTodo(id, _))
}

/// Get all todos as a list
/// Boundary: get_all_todos(store) -> List(Todo)
pub fn get_all_todos(store: Store) -> List(Todo) {
  process.call(store.subject, 5000, GetAllTodos(_))
}

/// Update a todo by ID
/// Boundary: update_todo(store, id: String, UpdateTodoInput) -> Result(Todo, String)
pub fn update_todo(
  store: Store,
  id: String,
  input: UpdateTodoInput,
) -> Result(Todo, String) {
  process.call(store.subject, 5000, UpdateTodo(id, input, _))
}

/// Delete a todo by ID
/// Boundary: delete_todo(store, id: String) -> Result(Nil, String)
pub fn delete_todo(store: Store, id: String) -> Result(Nil, String) {
  process.call(store.subject, 5000, DeleteTodo(id, _))
}

// ============================================================================
// Public API - Legacy Pid-based Interface (for backward compatibility)
// ============================================================================

/// Start an unsupervised actor instance
/// Returns: Result(Pid, Nil) per boundary contract
pub fn start_link() -> Result(Pid, Nil) {
  let initial_state = State(todos: dict.new(), next_id: 1)
  let builder =
    actor.new(initial_state)
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
    let initial_state = State(todos: dict.new(), next_id: 1)
    let builder =
      actor.new(initial_state)
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

/// Get a single todo by id (legacy Pid-based interface)
/// Returns: Result(Todo, Nil)
pub fn get(pid: Pid, id: String) -> Result(Todo, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { GetRaw(id, reply_to) })
      |> result.map_error(fn(_) { Nil })
    }
    Error(_) -> Error(Nil)
  }
}

/// Get all todos as a dictionary (legacy Pid-based interface)
/// Returns: Dict(String, Todo)
pub fn get_all(pid: Pid) -> Dict(String, Todo) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { GetAllRaw(reply_to) })
    }
    Error(_) -> dict.new()
  }
}

/// Store a todo (insert or update) - legacy Pid-based interface
/// Returns: Result(Nil, Nil)
pub fn put(pid: Pid, todo_item: Todo) -> Result(Nil, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { PutRaw(todo_item, reply_to) })
      |> result.map_error(fn(_) { Nil })
    }
    Error(_) -> Error(Nil)
  }
}

/// Delete a todo by id (legacy Pid-based interface)
/// Returns: Result(Nil, Nil)
pub fn delete(pid: Pid, id: String) -> Result(Nil, Nil) {
  case lookup_subject(pid) {
    Ok(subject) -> {
      process.call(subject, 5000, fn(reply_to) { DeleteRaw(id, reply_to) })
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
    // CRUD operations (modern interface)
    CreateTodo(title, description, reply_to) -> {
      let trimmed_title = string.trim(title)

      case string.is_empty(trimmed_title) {
        True -> {
          process.send(reply_to, Error("Title is required"))
          actor.continue(state)
        }
        False -> {
          let id = generate_id(state.next_id)
          let now = current_timestamp()
          let new_todo =
            Todo(
              id: id,
              title: trimmed_title,
              description: description,
              completed: False,
              created_at: now,
              updated_at: now,
            )

          let new_todos = dict.insert(state.todos, id, new_todo)
          let new_state = State(todos: new_todos, next_id: state.next_id + 1)

          process.send(reply_to, Ok(new_todo))
          actor.continue(new_state)
        }
      }
    }

    GetTodo(id, reply_to) -> {
      let result = dict.get(state.todos, id)
      let option_result = option.from_result(result)
      process.send(reply_to, option_result)
      actor.continue(state)
    }

    GetAllTodos(reply_to) -> {
      let todos = dict.values(state.todos)
      process.send(reply_to, todos)
      actor.continue(state)
    }

    UpdateTodo(id, input, reply_to) -> {
      case dict.get(state.todos, id) {
        Error(_) -> {
          process.send(reply_to, Error("Todo not found"))
          actor.continue(state)
        }
        Ok(existing) -> {
          let now = current_timestamp()
          let updated =
            Todo(
              id: existing.id,
              title: option.unwrap(input.title, existing.title),
              description: option.unwrap(input.description, existing.description),
              completed: option.unwrap(input.completed, existing.completed),
              created_at: existing.created_at,
              updated_at: now,
            )

          let new_todos = dict.insert(state.todos, id, updated)
          let new_state = State(..state, todos: new_todos)

          process.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
      }
    }

    DeleteTodo(id, reply_to) -> {
      case dict.has_key(state.todos, id) {
        False -> {
          process.send(reply_to, Error("Todo not found"))
          actor.continue(state)
        }
        True -> {
          let new_todos = dict.delete(state.todos, id)
          let new_state = State(..state, todos: new_todos)

          process.send(reply_to, Ok(Nil))
          actor.continue(new_state)
        }
      }
    }

    // Legacy raw operations (Pid-based interface)
    GetRaw(id, reply_to) -> {
      let result = dict.get(state.todos, id)
      process.send(reply_to, result)
      actor.continue(state)
    }

    GetAllRaw(reply_to) -> {
      process.send(reply_to, state.todos)
      actor.continue(state)
    }

    PutRaw(todo_item, reply_to) -> {
      let new_todos = dict.insert(state.todos, todo_item.id, todo_item)
      process.send(reply_to, Ok(Nil))
      actor.continue(State(..state, todos: new_todos))
    }

    DeleteRaw(id, reply_to) -> {
      let new_todos = dict.delete(state.todos, id)
      // Always succeed (idempotent delete)
      process.send(reply_to, Ok(Nil))
      actor.continue(State(..state, todos: new_todos))
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Generate a unique ID for todos
fn generate_id(counter: Int) -> String {
  let timestamp = current_timestamp()
  int_to_string(timestamp) <> "-" <> int_to_string(counter)
}

/// Get current timestamp (in Erlang, system_time in milliseconds)
@external(erlang, "erlang", "system_time")
fn system_time(unit: a) -> Int

fn current_timestamp() -> Int {
  system_time(1000)
}

/// Convert int to string
fn int_to_string(n: Int) -> String {
  do_int_to_string(n)
}

fn do_int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> {
      let quotient = n / 10
      let remainder = n % 10
      case quotient {
        0 -> do_int_to_string(remainder)
        _ -> do_int_to_string(quotient) <> do_int_to_string(remainder)
      }
    }
  }
}
