/// OTP Actor for in-memory todo storage
/// State format: Dict<String, Todo> where key is uuid, value is Todo record
/// Persists for the application lifetime

import gleam/erlang/process.{type Subject}
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/int
import models/todo_item.{type Todo}

/// Actor state: Dict<String, Todo>
pub type State =
  Dict(String, Todo)

/// Messages that the TodoActor accepts
/// External boundary contract for actor communication
pub type TodoActorMessage {
  /// Health check / ping
  Ping(reply: Subject(Pong))
  /// Get all todos from state
  GetAll(reply: Subject(Dict(String, Todo)))
  /// Get a single todo by ID
  GetById(id: String, reply: Subject(Option(Todo)))
  /// Add a new todo (actor generates UUID)
  AddTodo(
    title: String,
    description: Option(String),
    priority: String,
    reply: Subject(String),
  )
  /// Add a new todo with specific ID
  AddTodoWithId(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    reply: Subject(Result(Nil, Nil)),
  )
  /// Update todo completion status
  ToggleTodo(id: String, reply: Subject(Result(Todo, Nil)))
  /// Delete a todo by ID
  DeleteTodo(id: String, reply: Subject(Result(Nil, Nil)))
  /// Update existing todo
  UpdateTodo(id: String, title: Option(String), description: Option(Option(String)), priority: Option(String), reply: Subject(Result(Todo, Nil)))
}

/// Response type for ping
pub type Pong {
  Pong
}

/// Actor type alias
pub type TodoActor =
  Subject(TodoActorMessage)

/// Start the TodoActor with empty state
/// Returns Ok(actor) on success, Error(msg) on failure
pub fn start() -> Result(TodoActor, String) {
  // Initialize with empty Map<String, Todo>
  let initial_state: State = dict.new()

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start todo actor")
  }
}

/// Stop the todo actor
pub fn stop(actor: TodoActor) -> Nil {
  process.send(actor, Ping(process.new_subject()))
  Nil
}

/// Message handler - maintains state consistency
fn handle_message(
  state: State,
  msg: TodoActorMessage,
) -> actor.Next(State, TodoActorMessage) {
  case msg {
    Ping(reply) -> {
      process.send(reply, Pong)
      actor.continue(state)
    }

    GetAll(reply) -> {
      process.send(reply, state)
      actor.continue(state)
    }

    GetById(id, reply) -> {
      process.send(reply, dict.get(state, id) |> option.from_result)
      actor.continue(state)
    }

    AddTodo(title, description, priority_str, reply) -> {
      let id = generate_uuid()
      let priority = todo_item.parse_priority(priority_str)
      let new_todo = todo_item.new(id, title, description, priority)
      let new_state = dict.insert(state, id, new_todo)
      process.send(reply, id)
      actor.continue(new_state)
    }

    AddTodoWithId(id, title, description, priority_str, reply) -> {
      case dict.has_key(state, id) {
        True -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
        False -> {
          let priority = todo_item.parse_priority(priority_str)
          let new_todo = todo_item.new(id, title, description, priority)
          let new_state = dict.insert(state, id, new_todo)
          process.send(reply, Ok(Nil))
          actor.continue(new_state)
        }
      }
    }

    ToggleTodo(id, reply) -> {
      case dict.get(state, id) {
        Ok(existing) -> {
          let updated = todo_item.toggle(existing)
          let new_state = dict.insert(state, id, updated)
          process.send(reply, Ok(updated))
          actor.continue(new_state)
        }
        Error(Nil) -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
    }

    DeleteTodo(id, reply) -> {
      case dict.has_key(state, id) {
        True -> {
          let new_state = dict.delete(state, id)
          process.send(reply, Ok(Nil))
          actor.continue(new_state)
        }
        False -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
    }

    UpdateTodo(id, title, description, priority_str, reply) -> {
      case dict.get(state, id) {
        Ok(existing) -> {
          let updated_title = case title {
            Some(t) -> t
            None -> existing.title
          }
          let updated_description = case description {
            Some(d) -> d
            None -> existing.description
          }
          let updated_priority = case priority_str {
            Some(p) -> todo_item.parse_priority(p)
            None -> existing.priority
          }
          let updated = todo_item.Todo(
            ..existing,
            title: updated_title,
            description: updated_description,
            priority: updated_priority,
          )
          let new_state = dict.insert(state, id, updated)
          process.send(reply, Ok(updated))
          actor.continue(new_state)
        }
        Error(Nil) -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
    }
  }
}

/// Simple UUID generator for todo IDs
fn generate_uuid() -> String {
  "todo-" <> int.to_string(int.random(1_000_000_000))
}

/// Public API: Ping the actor
pub fn ping(actor: TodoActor) -> Result(Pong, Nil) {
  let subject = process.new_subject()
  process.send(actor, Ping(subject))
  process.receive(subject, 5000)
}

/// Public API: Get all todos
pub fn get_all(actor: TodoActor) -> Dict(String, Todo) {
  let subject = process.new_subject()
  process.send(actor, GetAll(subject))
  case process.receive(subject, 5000) {
    Ok(state) -> state
    Error(_) -> dict.new()
  }
}

/// Public API: Get todo by ID
pub fn get_by_id(actor: TodoActor, id: String) -> Option(Todo) {
  let subject = process.new_subject()
  process.send(actor, GetById(id, subject))
  case process.receive(subject, 5000) {
    Ok(item) -> item
    Error(_) -> option.None
  }
}

/// Public API: Add a new todo
pub fn add(
  actor: TodoActor,
  title: String,
  description: Option(String),
  priority: String,
) -> String {
  let subject = process.new_subject()
  process.send(actor, AddTodo(title, description, priority, subject))
  case process.receive(subject, 5000) {
    Ok(id) -> id
    Error(_) -> ""
  }
}

/// Public API: Add a new todo with specific ID
pub fn add_with_id(
  actor: TodoActor,
  id: String,
  title: String,
  description: Option(String),
  priority: String,
) -> Result(Nil, Nil) {
  let subject = process.new_subject()
  process.send(actor, AddTodoWithId(id, title, description, priority, subject))
  case process.receive(subject, 5000) {
    Ok(result) -> result
    Error(_) -> Error(Nil)
  }
}

/// Public API: Toggle todo completion
pub fn toggle(actor: TodoActor, id: String) -> Result(Todo, Nil) {
  let subject = process.new_subject()
  process.send(actor, ToggleTodo(id, subject))
  case process.receive(subject, 5000) {
    Ok(result) -> result
    Error(_) -> Error(Nil)
  }
}

/// Public API: Delete a todo
pub fn delete(actor: TodoActor, id: String) -> Result(Nil, Nil) {
  let subject = process.new_subject()
  process.send(actor, DeleteTodo(id, subject))
  case process.receive(subject, 5000) {
    Ok(result) -> result
    Error(_) -> Error(Nil)
  }
}
