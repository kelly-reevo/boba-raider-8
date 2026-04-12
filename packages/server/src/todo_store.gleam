import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string

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
  )
}

pub type TodoItem {
  TodoItem(
    id: String,
    title: String,
    description: Option(String),
    priority: Priority,
    completed: Bool,
  )
}

pub type UpdateResult {
  Ok
  NotFound
}

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
          )
          let new_todos = dict.insert(state.todos, id, updated)
          process.send(reply_to, Ok)
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
          process.send(reply_to, Ok)
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
