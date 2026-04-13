import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import models/todo_item.{type Todo}

/// Messages handled by the todo actor
pub type Message {
  /// Create a new todo
  Create(data: CreateTodoData, reply_to: Subject(Todo))
  /// Get all todos
  GetAll(reply_to: Subject(List(Todo)))
  /// Get a single todo by ID
  Get(id: String, reply_to: Subject(Result(Todo, Nil)))
  /// Update an existing todo
  Update(id: String, updates: UpdateRequest, reply_to: Subject(UpdateResult))
  /// Delete a todo by ID
  Delete(id: String, reply_to: Subject(Result(Nil, Nil)))
}

/// Input data for creating a new todo
pub type CreateTodoData {
  CreateTodoData(
    title: String,
    description: String,
    priority: String,
    completed: Bool,
  )
}

/// Partial update request - only provided fields are updated
pub type UpdateRequest {
  UpdateRequest(
    title: Option(String),
    description: Option(String),
    priority: Option(String),
    completed: Option(Bool),
  )
}

/// Result of update operation
pub type UpdateResult {
  Updated(Todo)
  NotFound
}

/// Actor handle type
pub type TodoActor =
  Subject(Message)

/// Actor state: in-memory store of todos keyed by ID
pub type State {
  State(todos: Dict(String, Todo))
}

/// Generate a UUID v4 string
@external(erlang, "todo_actor_ffi", "generate_uuid")
fn generate_uuid() -> String

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn current_timestamp_millis() -> Int

/// Create a new todo from input data with generated ID and timestamp
fn create_todo(data: CreateTodoData) -> Todo {
  let now = current_timestamp_millis()
  todo_item.new(
    generate_uuid(),
    data.title,
    Some(data.description),
    todo_item.parse_priority(data.priority),
    now,
  )
}

/// Merge partial updates into an existing todo
fn merge_todo(existing: Todo, updates: UpdateRequest, now: Int) -> Todo {
  let updated_title = case updates.title {
    Some(t) -> t
    None -> existing.title
  }
  let updated_description = case updates.description {
    Some(d) -> Some(d)
    None -> existing.description
  }
  let updated_priority = case updates.priority {
    Some(p) -> todo_item.parse_priority(p)
    None -> existing.priority
  }
  let updated_completed = case updates.completed {
    Some(c) -> c
    None -> existing.completed
  }
  todo_item.Todo(
    ..existing,
    title: updated_title,
    description: updated_description,
    priority: updated_priority,
    completed: updated_completed,
    updated_at: now,
  )
}

/// Initialize empty actor state
fn initial_state() -> State {
  State(todos: dict.new())
}

/// Handle incoming messages and update state
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

    // Update: merge partial updates into existing todo
    Update(id, updates, reply_to) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let now = current_timestamp_millis()
          let updated = merge_todo(existing, updates, now)
          let new_todos = dict.insert(state.todos, id, updated)
          process.send(reply_to, Updated(updated))
          actor.continue(State(todos: new_todos))
        }
        Error(_) -> {
          process.send(reply_to, NotFound)
          actor.continue(state)
        }
      }
    }

    // Delete: remove a todo by ID
    Delete(id, reply_to) -> {
      case dict.has_key(state.todos, id) {
        True -> {
          let new_todos = dict.delete(state.todos, id)
          process.send(reply_to, Ok(Nil))
          actor.continue(State(todos: new_todos))
        }
        False -> {
          process.send(reply_to, Error(Nil))
          actor.continue(state)
        }
      }
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
  process.call(actor, 5000, fn(subject) { Create(data, subject) })
}

/// Helper: Get all todos
pub fn get_all(actor: TodoActor) -> List(Todo) {
  process.call(actor, 5000, fn(subject) { GetAll(subject) })
}

/// Helper: Get a single todo by ID
pub fn get(actor: TodoActor, id: String) -> Result(Todo, Nil) {
  process.call(actor, 5000, fn(subject) { Get(id, subject) })
}

/// Helper: Update a todo with partial fields
pub fn update(actor: TodoActor, id: String, updates: UpdateRequest) -> UpdateResult {
  process.call(actor, 5000, fn(subject) { Update(id, updates, subject) })
}

/// Helper: Delete a todo by ID
pub fn delete(actor: TodoActor, id: String) -> Result(Nil, Nil) {
  process.call(actor, 5000, fn(subject) { Delete(id, subject) })
}
