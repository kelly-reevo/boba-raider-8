/// Todo store - OTP actor with filtering support

import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/dict.{type Dict}
import gleam/list
import gleam/int
import gleam/order
import gleam/string
import gleam/option
import shared.{type Todo, type UpdateTodoInput, type AppError, NotFound}

// Internal state for the store actor
type StoreState {
  StoreState(
    todos: Dict(String, Todo),
    next_id: Int,
  )
}

// Actor messages
type StoreMessage {
  CreateTodo(
    reply_to: Subject(Result(Todo, AppError)),
    title: String,
    description: String,
  )
  UpdateTodo(
    reply_to: Subject(Result(Todo, AppError)),
    id: String,
    input: UpdateTodoInput,
  )
  ListAll(
    reply_to: Subject(Result(List(Todo), AppError)),
    filter: String,
  )
}

/// Store handle type (actor subject)
pub opaque type Store {
  Store(Subject(StoreMessage))
}

/// Start the todo store actor
pub fn start() -> Result(Store, String) {
  let initial_state = StoreState(todos: dict.new(), next_id: 1)

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(server) -> Ok(Store(server.data))
    Error(_) -> Error("Failed to start todo store")
  }
}

// Actor message handler
fn handle_message(
  state: StoreState,
  msg: StoreMessage,
) -> actor.Next(StoreState, StoreMessage) {
  case msg {
    CreateTodo(reply_to, title, description) -> {
      let now = current_timestamp_millis()
      let id = "todo-" <> int.to_string(state.next_id)
      let new_item = shared.Todo(
        id: id,
        title: title,
        description: description,
        completed: False,
        created_at: now,
        updated_at: now,
      )
      let new_todos = dict.insert(state.todos, id, new_item)
      let new_state = StoreState(
        todos: new_todos,
        next_id: state.next_id + 1,
      )
      process.send(reply_to, Ok(new_item))
      actor.continue(new_state)
    }

    UpdateTodo(reply_to, id, input) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let updated_title = case input.title {
            option.Some(t) -> t
            option.None -> existing.title
          }
          let updated_desc = case input.description {
            option.Some(d) -> d
            option.None -> existing.description
          }
          let updated_completed = case input.completed {
            option.Some(c) -> c
            option.None -> existing.completed
          }
          let updated = shared.Todo(
            id: existing.id,
            title: updated_title,
            description: updated_desc,
            completed: updated_completed,
            created_at: existing.created_at,
            updated_at: current_timestamp_millis(),
          )
          let new_todos = dict.insert(state.todos, id, updated)
          let new_state = StoreState(..state, todos: new_todos)
          process.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply_to, Error(NotFound("Todo not found: " <> id)))
          actor.continue(state)
        }
      }
    }

    ListAll(reply_to, filter) -> {
      let all_todos = dict.values(state.todos)
      let filtered = apply_filter(all_todos, filter)
      let sorted = sort_by_created_at_desc(filtered)
      process.send(reply_to, Ok(sorted))
      actor.continue(state)
    }
  }
}

/// Create a new todo
pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, AppError) {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, CreateTodo(reply_subject, title, description))
  let assert Ok(result) = process.receive(reply_subject, 5000)
  result
}

/// Update an existing todo
pub fn update_todo(
  store: Store,
  id: String,
  input: UpdateTodoInput,
) -> Result(Todo, AppError) {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, UpdateTodo(reply_subject, id, input))
  let assert Ok(result) = process.receive(reply_subject, 5000)
  result
}

/// List all todos with optional filtering
/// Filter values: "all", "active", "completed"
/// Invalid filter defaults to "all"
pub fn list_all(store: Store, filter: String) -> Result(List(Todo), AppError) {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, ListAll(reply_subject, filter))
  let assert Ok(result) = process.receive(reply_subject, 5000)
  result
}

// Apply filter to todos list
// "all" - all todos
// "active" - only completed=false
// "completed" - only completed=true
// Invalid filter defaults to "all"
fn apply_filter(todos: List(Todo), filter: String) -> List(Todo) {
  case string.lowercase(filter) {
    "all" -> todos
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

// Sort todos by created_at descending (newest first)
// Uses ID as secondary sort key for stable ordering when timestamps are equal
fn sort_by_created_at_desc(todos: List(Todo)) -> List(Todo) {
  list.sort(todos, fn(a, b) {
    case int.compare(a.created_at, b.created_at) {
      order.Gt -> order.Lt
      order.Lt -> order.Gt
      order.Eq -> {
        // Secondary sort by ID descending (todo-3 > todo-2 > todo-1)
        order.reverse(string.compare)(a.id, b.id)
      }
    }
  })
}

// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn current_timestamp_millis() -> Int {
  // 1000 = millisecond unit for Erlang system_time
  system_time(1000)
}
