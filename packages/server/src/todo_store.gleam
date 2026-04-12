import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import shared

pub type Priority {
  Low
  Medium
  High
}

pub type TodoData {
  TodoData(
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
    created_at: String,
    updated_at: String,
  )
}

pub type TodoItem {
  TodoItem(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
    created_at: String,
    updated_at: String,
  )
}

pub type UpdateResult {
  UpdateOk
  NotFound
}

// Re-export shared UpdateTodoInput for convenience
pub type UpdateTodoInput = shared.UpdateTodoInput

pub opaque type Store {
  Store(todos: Dict(String, TodoItem))
}

type Message {
  Insert(data: TodoData, reply_to: Subject(String))
  Update(id: String, data: TodoData, reply_to: Subject(UpdateResult))
  Delete(id: String, reply_to: Subject(UpdateResult))
  Get(id: String, reply_to: Subject(Option(TodoItem)))
  List(reply_to: Subject(List(TodoItem)))
}

pub opaque type TodoStore {
  TodoStore(Subject(Message))
}

pub fn start() -> Result(TodoStore, String) {
  let initial_state = Store(todos: dict.new())

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start()
  |> result.map(fn(s) { TodoStore(s.data) })
  |> result.map_error(fn(_) { "Failed to start todo store actor" })
}

fn handle_message(state: Store, msg: Message) -> actor.Next(Store, Message) {
  case msg {
    Insert(data, reply_to) -> {
      let id = generate_uuid()
      let item = TodoItem(
        id: id,
        title: data.title,
        description: data.description,
        priority: data.priority,
        completed: data.completed,
        created_at: data.created_at,
        updated_at: data.updated_at,
      )
      let new_todos = dict.insert(state.todos, id, item)
      process.send(reply_to, id)
      actor.continue(Store(todos: new_todos))
    }

    Update(id, data, reply_to) -> {
      let existing = dict.get(state.todos, id)
      case result.is_ok(existing) {
        True -> {
          let item = result.lazy_unwrap(existing, fn() { panic })
          let updated = TodoItem(
            id: item.id,
            title: data.title,
            description: data.description,
            priority: data.priority,
            completed: data.completed,
            created_at: item.created_at,
            updated_at: data.updated_at,
          )
          let new_todos = dict.insert(state.todos, id, updated)
          process.send(reply_to, UpdateOk)
          actor.continue(Store(todos: new_todos))
        }
        False -> {
          process.send(reply_to, NotFound)
          actor.continue(state)
        }
      }
    }

    Delete(id, reply_to) -> {
      case dict.has_key(state.todos, id) {
        True -> {
          let new_todos = dict.delete(state.todos, id)
          process.send(reply_to, UpdateOk)
          actor.continue(Store(todos: new_todos))
        }
        False -> {
          process.send(reply_to, NotFound)
          actor.continue(state)
        }
      }
    }

    Get(id, reply_to) -> {
      let res = dict.get(state.todos, id)
      let out = case result.is_ok(res) {
        True -> Some(result.lazy_unwrap(res, fn() { panic }))
        False -> None
      }
      process.send(reply_to, out)
      actor.continue(state)
    }

    List(reply_to) -> {
      let todos = dict.values(state.todos)
      process.send(reply_to, todos)
      actor.continue(state)
    }
  }
}

fn generate_uuid() -> String {
  let timestamp = erlang_monotonic_time()
  let random = erlang_unique_integer()
  string.inspect(timestamp) <> "-" <> string.inspect(random)
}

@external(erlang, "erlang", "monotonic_time")
fn erlang_monotonic_time() -> Int

@external(erlang, "erlang", "unique_integer")
fn erlang_unique_integer() -> Int

pub fn insert(store: TodoStore, data: TodoData) -> String {
  let TodoStore(subject) = store
  let reply_subject = process.new_subject()
  process.send(subject, Insert(data, reply_subject))
  let received = process.receive(reply_subject, 5000)
  result.unwrap(received, "")
}

pub fn update(store: TodoStore, id: String, data: TodoData) -> UpdateResult {
  let TodoStore(subject) = store
  let reply_subject = process.new_subject()
  process.send(subject, Update(id, data, reply_subject))
  let received = process.receive(reply_subject, 5000)
  result.unwrap(received, NotFound)
}

pub fn delete(store: TodoStore, id: String) -> UpdateResult {
  let TodoStore(subject) = store
  let reply_subject = process.new_subject()
  process.send(subject, Delete(id, reply_subject))
  let received = process.receive(reply_subject, 5000)
  result.unwrap(received, NotFound)
}

pub fn get(store: TodoStore, id: String) -> Option(TodoItem) {
  let TodoStore(subject) = store
  let reply_subject = process.new_subject()
  process.send(subject, Get(id, reply_subject))
  let received = process.receive(reply_subject, 5000)
  result.unwrap(received, None)
}

pub fn list(store: TodoStore) -> List(TodoItem) {
  let TodoStore(subject) = store
  let reply_subject = process.new_subject()
  process.send(subject, List(reply_subject))
  let received = process.receive(reply_subject, 5000)
  result.unwrap(received, [])
}

// Helper function to create a new todo with server-generated timestamps
pub fn create_todo(
  store: TodoStore,
  title: String,
  description: Option(String),
) -> Result(TodoItem, String) {
  let timestamp = generate_iso_timestamp()
  let data = TodoData(
    title: title,
    description: description,
    priority: Medium,
    completed: False,
    created_at: timestamp,
    updated_at: timestamp,
  )
  let id = insert(store, data)
  case id {
    "" -> Error("Failed to create todo")
    _ -> {
      case get(store, id) {
        Some(item) -> Ok(item)
        None -> Error("Failed to retrieve created todo")
      }
    }
  }
}

// Helper function to update a todo by ID using UpdateTodoInput fields
pub fn update_todo(
  store: TodoStore,
  id: String,
  input: UpdateTodoInput,
) -> Result(TodoItem, String) {
  case get(store, id) {
    None -> Error("Todo not found")
    Some(existing) -> {
      let timestamp = generate_iso_timestamp()
      let new_title = case input.title {
        Some(t) -> t
        None -> existing.title
      }
      let new_description = case input.description {
        Some(d) -> Some(d)
        None -> existing.description
      }
      let new_completed = case input.completed {
        Some(c) -> c
        None -> existing.completed
      }
      let data = TodoData(
        title: new_title,
        description: new_description,
        priority: existing.priority,
        completed: new_completed,
        created_at: existing.created_at,
        updated_at: timestamp,
      )
      case update(store, id, data) {
        UpdateOk -> {
          case get(store, id) {
            Some(item) -> Ok(item)
            None -> Error("Failed to retrieve updated todo")
          }
        }
        NotFound -> Error("Todo not found")
      }
    }
  }
}

// Generate ISO8601 timestamp string
fn generate_iso_timestamp() -> String {
  let seconds = system_time_seconds()
  format_iso8601(seconds)
}

// Get current time in seconds since epoch
@external(erlang, "erlang", "system_time")
fn system_time_seconds() -> Int

// Format seconds as ISO8601 UTC string: YYYY-MM-DDTHH:MM:SSZ
fn format_iso8601(seconds: Int) -> String {
  let days_since_epoch = seconds / 86_400
  let seconds_in_day = seconds % 86_400
  let year = 1970 + days_since_epoch / 365
  let day_of_year = days_since_epoch % 365
  let month = day_of_year / 30 + 1
  let day = day_of_year % 30 + 1
  let hour = seconds_in_day / 3600
  let minute = { seconds_in_day % 3600 } / 60
  let second = seconds_in_day % 60
  int_to_padded_string(year, 4) <> "-" <> int_to_padded_string(month, 2) <> "-" <> int_to_padded_string(day, 2) <> "T" <> int_to_padded_string(hour, 2) <> ":" <> int_to_padded_string(minute, 2) <> ":" <> int_to_padded_string(second, 2) <> "Z"
}

// Convert integer to zero-padded string
fn int_to_padded_string(n: Int, width: Int) -> String {
  let str = int_to_string(n)
  let len = string.length(str)
  case len >= width {
    True -> str
    False -> string.repeat("0", width - len) <> str
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String
