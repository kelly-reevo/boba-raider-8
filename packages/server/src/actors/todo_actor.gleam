import gleam/erlang/process
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/dict.{type Dict}

/// Todo item with all fields
pub type Todo {
  Todo(
    id: String,
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

/// Messages that can be sent to the todo actor
pub type TodoMessage {
  UpdateTodo(id: String, updates: UpdateRequest, reply_to: process.Subject(UpdateResult))
  CreateTodo(item: Todo, reply_to: process.Subject(Todo))
  GetTodo(id: String, reply_to: process.Subject(Option(Todo)))
}

/// Actor state is a dictionary of todos keyed by id
pub type State {
  State(todos: Dict(String, Todo))
}

/// Start the todo actor using the builder pattern
pub fn start() {
  actor.new(State(dict.new()))
  |> actor.on_message(handle_message)
  |> actor.start()
}

/// Message handler for the todo actor
/// Takes state first, then message, returns actor.Next
fn handle_message(state: State, message: TodoMessage) {
  case message {
    UpdateTodo(id, updates, reply_to) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let updated = merge_todo(existing, updates)
          let new_todos = dict.insert(state.todos, id, updated)
          process.send(reply_to, Updated(updated))
          actor.continue(State(new_todos))
        }
        Error(_) -> {
          process.send(reply_to, NotFound)
          actor.continue(state)
        }
      }
    }

    CreateTodo(item, reply_to) -> {
      let new_todos = dict.insert(state.todos, item.id, item)
      process.send(reply_to, item)
      actor.continue(State(new_todos))
    }

    GetTodo(id, reply_to) -> {
      let item = dict.get(state.todos, id) |> option.from_result
      process.send(reply_to, item)
      actor.continue(state)
    }
  }
}

/// Merge partial updates into an existing todo
fn merge_todo(existing: Todo, updates: UpdateRequest) -> Todo {
  Todo(
    id: existing.id,
    title: option.unwrap(updates.title, existing.title),
    description: option.unwrap(updates.description, existing.description),
    priority: option.unwrap(updates.priority, existing.priority),
    completed: option.unwrap(updates.completed, existing.completed),
  )
}
