import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor

/// Priority levels for todo items
pub type Priority {
  Low
  Medium
  High
}

/// Complete todo item with all fields
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
    created_at: String,
  )
}

/// Input data for creating a new todo (no id or created_at)
pub type CreateTodoData {
  CreateTodoData(
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
  )
}

/// Actor state: in-memory store of todos keyed by ID
pub type State {
  State(todos: Dict(String, Todo))
}

/// Messages handled by the todo actor
pub type Message {
  /// Create a new todo: accepts todo data, returns created todo with ID and timestamp
  Create(data: CreateTodoData, reply_to: Subject(Todo))

  /// Get all todos as a list
  GetAll(reply_to: Subject(List(Todo)))

  /// Get a single todo by ID
  Get(id: String, reply_to: Subject(Result(Todo, Nil)))

  /// Update an existing todo (cast, no reply)
  Put(id: String, item: Todo)

  /// Delete a todo by ID (cast, no reply)
  Delete(id: String)
}

/// Actor handle type
pub type TodoActor =
  Subject(Message)

/// Generate a UUID v4 string
@external(erlang, "todo_actor_ffi", "generate_uuid")
fn generate_uuid() -> String

/// Get current ISO8601 datetime string
@external(erlang, "todo_actor_ffi", "current_datetime")
fn current_datetime() -> String

/// Create a new todo from input data with generated ID and timestamp
fn create_todo(data: CreateTodoData) -> Todo {
  Todo(
    id: generate_uuid(),
    title: data.title,
    description: data.description,
    priority: data.priority,
    completed: data.completed,
    created_at: current_datetime(),
  )
}

/// Initialize empty actor state
fn initial_state() -> State {
  State(todos: dict.new())
}

/// Handle incoming messages and update state
/// Note: API uses (state, message) order and Next(state, message) return type
fn handle_message(state: State, msg: Message) -> actor.Next(State, Message) {
  case msg {
    // Create: accept todo data, generate ID/timestamp, persist, return created todo
    Create(data, reply_to) -> {
      let item = create_todo(data)
      let new_todos = dict.insert(state.todos, item.id, item)
      let new_state = State(todos: new_todos)

      process.send(reply_to, item)
      actor.continue(new_state)
    }

    // GetAll: return list of all todos
    GetAll(reply_to) -> {
      let all_todos = dict.values(state.todos)
      process.send(reply_to, all_todos)
      actor.continue(state)
    }

    // Get: return single todo by ID if found
    Get(id, reply_to) -> {
      let result = case dict.get(state.todos, id) {
        Ok(item) -> Ok(item)
        Error(_) -> Error(Nil)
      }
      process.send(reply_to, result)
      actor.continue(state)
    }

    // Put: update/insert a todo (cast, no reply)
    Put(id, item) -> {
      let new_todos = dict.insert(state.todos, id, item)
      actor.continue(State(todos: new_todos))
    }

    // Delete: remove a todo by ID (cast, no reply)
    Delete(id) -> {
      let new_todos = dict.delete(state.todos, id)
      actor.continue(State(todos: new_todos))
    }
  }
}

/// Start the todo actor with empty state
pub fn start() -> Result(TodoActor, String) {
  let result =
    actor.new(initial_state())
    |> actor.on_message(handle_message)
    |> actor.start()

  case result {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start todo actor")
  }
}

/// Helper: Create a new todo and wait for response
pub fn create(actor: TodoActor, data: CreateTodoData) -> Todo {
  actor.call(actor, 5000, fn(subject) { Create(data, subject) })
}

/// Helper: Get all todos
pub fn get_all(actor: TodoActor) -> List(Todo) {
  actor.call(actor, 5000, fn(subject) { GetAll(subject) })
}

/// Helper: Get a single todo by ID
pub fn get(actor: TodoActor, id: String) -> Result(Todo, Nil) {
  actor.call(actor, 5000, fn(subject) { Get(id, subject) })
}

/// Helper: Update/insert a todo (cast, no waiting)
pub fn put(actor: TodoActor, id: String, item: Todo) -> Nil {
  process.send(actor, Put(id, item))
}

/// Helper: Delete a todo by ID (cast, no waiting)
pub fn delete(actor: TodoActor, id: String) -> Nil {
  process.send(actor, Delete(id))
}
