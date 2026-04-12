/// Todo store - OTP actor with full CRUD and filtering support

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/string
import shared.{type Todo, type UpdateTodoInput, NotFound}

// Internal state for the store actor
type StoreState {
  StoreState(
    todos: Dict(String, Todo),
    next_id: Int,
  )
}

// Actor messages
type StoreMsg {
  Create(
    payload: List(#(String, String)),
    reply: Subject(CreateResult),
  )
  Get(
    id: String,
    reply: Subject(GetResult),
  )
  Update(
    id: String,
    changes: List(#(String, String)),
    reply: Subject(UpdateResult),
  )
  Delete(
    id: String,
    reply: Subject(DeleteResult),
  )
  ListAll(
    reply: Subject(ListResult),
    filter: String,
  )
}

// Result types for internal message handling
type CreateResult {
  CreateSuccess(Todo)
  CreateValidationError(List(String))
}

type GetResult {
  GetSuccess(Todo)
  GetNotFound
}

type UpdateResult {
  UpdateSuccess(Todo)
  UpdateNotFound
  UpdateValidationError(List(String))
}

type DeleteResult {
  DeleteOk
  DeleteNotFound
}

type ListResult {
  ListSuccess(List(Todo))
}

/// Store handle type (actor subject)
pub opaque type Store {
  Store(Subject(StoreMsg))
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

// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn current_timestamp_millis() -> Int {
  // 1000 = millisecond unit for Erlang system_time
  system_time(1000)
}

// Generate a unique ID
fn generate_id(counter: Int) -> String {
  let now = current_timestamp_millis()
  "todo-" <> int.to_string(counter) <> "-" <> int.to_string(now)
}

// Actor message handler
fn handle_message(
  state: StoreState,
  msg: StoreMsg,
) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    Create(payload, reply) -> {
      let id = generate_id(state.next_id)
      let result = do_create(payload, id)
      process.send(reply, result)
      case result {
        CreateSuccess(item) -> {
          let new_todos = dict.insert(state.todos, item.id, item)
          let new_state = StoreState(
            todos: new_todos,
            next_id: state.next_id + 1,
          )
          actor.continue(new_state)
        }
        CreateValidationError(_) -> {
          actor.continue(StoreState(..state, next_id: state.next_id + 1))
        }
      }
    }

    Get(id, reply) -> {
      process.send(reply, do_get(state, id))
      actor.continue(state)
    }

    Update(id, changes, reply) -> {
      let result = do_update(state, id, changes)
      process.send(reply, result)
      case result {
        UpdateSuccess(item) -> {
          let new_todos = dict.insert(state.todos, item.id, item)
          actor.continue(StoreState(..state, todos: new_todos))
        }
        UpdateNotFound -> actor.continue(state)
        UpdateValidationError(_) -> actor.continue(state)
      }
    }

    Delete(id, reply) -> {
      let result = do_delete(state, id)
      process.send(reply, result)
      case result {
        DeleteOk -> {
          let new_todos = dict.delete(state.todos, id)
          actor.continue(StoreState(..state, todos: new_todos))
        }
        DeleteNotFound -> actor.continue(state)
      }
    }

    ListAll(reply, filter) -> {
      let all_todos = dict.values(state.todos)
      let filtered = apply_filter(all_todos, filter)
      let sorted = sort_by_created_at_desc(filtered)
      process.send(reply, ListSuccess(sorted))
      actor.continue(state)
    }
  }
}

fn do_create(payload: List(#(String, String)), id: String) -> CreateResult {
  case validate_create(payload) {
    [] -> {
      let title = get_field(payload, "title") |> option.unwrap("")
      let description = case get_field(payload, "description") {
        Some("") -> ""
        Some(d) -> d
        None -> ""
      }
      let now = current_timestamp_millis()

      let new_item = Todo(
        id: id,
        title: title,
        description: description,
        completed: False,
        created_at: now,
        updated_at: now,
      )
      CreateSuccess(new_item)
    }
    errors -> CreateValidationError(errors)
  }
}

fn do_get(state: StoreState, id: String) -> GetResult {
  case dict.get(state.todos, id) {
    Ok(item) -> GetSuccess(item)
    Error(_) -> GetNotFound
  }
}

fn do_update(
  state: StoreState,
  id: String,
  changes: List(#(String, String)),
) -> UpdateResult {
  case dict.get(state.todos, id) {
    Ok(existing) -> {
      case validate_update(changes) {
        [] -> {
          let title = case get_field(changes, "title") {
            Some(t) -> t
            None -> existing.title
          }
          let description = case get_field(changes, "description") {
            Some("") -> ""
            Some(d) -> d
            None -> existing.description
          }
          let completed = case get_field(changes, "completed") {
            Some("true") -> True
            Some("false") -> False
            Some(_) -> existing.completed
            None -> existing.completed
          }

          let updated = Todo(
            id: existing.id,
            title: title,
            description: description,
            completed: completed,
            created_at: existing.created_at,
            updated_at: current_timestamp_millis(),
          )
          UpdateSuccess(updated)
        }
        errors -> UpdateValidationError(errors)
      }
    }
    Error(_) -> UpdateNotFound
  }
}

fn do_delete(state: StoreState, id: String) -> DeleteResult {
  case dict.get(state.todos, id) {
    Ok(_existing) -> DeleteOk
    Error(_) -> DeleteNotFound
  }
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
fn sort_by_created_at_desc(todos: List(Todo)) -> List(Todo) {
  list.sort(todos, fn(a, b) {
    case int.compare(a.created_at, b.created_at) {
      order.Gt -> order.Lt
      order.Lt -> order.Gt
      order.Eq -> order.Eq
    }
  })
}

fn get_field(payload: List(#(String, String)), key: String) -> Option(String) {
  list.find(payload, fn(field) { field.0 == key })
  |> option.from_result()
  |> option.map(fn(field) { field.1 })
}

fn validate_create(payload: List(#(String, String))) -> List(String) {
  let errors = []

  let errors = case get_field(payload, "title") {
    None -> ["title is required", ..errors]
    Some("") -> ["title is required", ..errors]
    _ -> errors
  }

  list.reverse(errors)
}

fn validate_update(changes: List(#(String, String))) -> List(String) {
  let errors = []

  let errors = case get_field(changes, "completed") {
    Some(v) if v != "true" && v != "false" && v != "" -> [
      "completed must be true or false", ..errors
    ]
    _ -> errors
  }

  list.reverse(errors)
}

// Result types for public API matching test expectations

pub type CreateApiResult {
  CreateOkResult(Todo)
  CreateErrorResult(CreateErrorType)
}

pub type CreateErrorType {
  ValidationErrorCreate(List(String))
}

pub type GetApiResult {
  GetOkResult(Todo)
  GetErrorResult(GetErrorType)
}

pub type GetErrorType {
  NotFoundGet
}

pub type UpdateApiResult {
  UpdateOkResult(Todo)
  UpdateErrorResult(UpdateErrorType)
}

pub type UpdateErrorType {
  NotFoundUpdate
  ValidationErrorUpdate(List(String))
}

pub type DeleteApiResult {
  DeleteOkResult
  DeleteErrorResult(DeleteErrorType)
}

pub type DeleteErrorType {
  NotFoundDelete
}

pub type ListApiResult {
  ListOkResult(List(Todo))
  ListErrorResult(ListErrorType)
}

pub type ListErrorType {
  ListStoreError
}

// Public API for synchronous calls returning the exact format tests expect

pub fn create_api(
  store: Store,
  payload: List(#(String, String)),
) -> CreateApiResult {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, Create(payload, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(CreateSuccess(item)) -> CreateOkResult(item)
    Ok(CreateValidationError(errors)) -> CreateErrorResult(ValidationErrorCreate(errors))
    _ -> CreateErrorResult(ValidationErrorCreate(["timeout"]))
  }
}

pub fn get_api(store: Store, id: String) -> GetApiResult {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, Get(id, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(GetSuccess(item)) -> GetOkResult(item)
    Ok(GetNotFound) | _ -> GetErrorResult(NotFoundGet)
  }
}

pub fn update_api(
  store: Store,
  id: String,
  changes: List(#(String, String)),
) -> UpdateApiResult {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, Update(id, changes, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(UpdateSuccess(item)) -> UpdateOkResult(item)
    Ok(UpdateNotFound) -> UpdateErrorResult(NotFoundUpdate)
    Ok(UpdateValidationError(errors)) -> UpdateErrorResult(ValidationErrorUpdate(errors))
    _ -> UpdateErrorResult(NotFoundUpdate)
  }
}

pub fn delete_api(store: Store, id: String) -> DeleteApiResult {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, Delete(id, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(DeleteOk) -> DeleteOkResult
    Ok(DeleteNotFound) | _ -> DeleteErrorResult(NotFoundDelete)
  }
}

/// List all todos with optional filtering
/// Filter values: "all", "active", "completed"
/// Invalid filter defaults to "all"
pub fn list_all(store: Store, filter: String) -> ListApiResult {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, ListAll(reply_subject, filter))

  case process.receive(reply_subject, 5000) {
    Ok(ListSuccess(todos)) -> ListOkResult(todos)
    _ -> ListErrorResult(ListStoreError)
  }
}

// New-style public API using shared types

/// Create a new todo using shared types
pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, shared.AppError) {
  let payload = [
    #("title", title),
    #("description", description),
  ]
  case create_api(store, payload) {
    CreateOkResult(todo) -> Ok(todo)
    CreateErrorResult(ValidationErrorCreate(errors)) ->
      Error(shared.InvalidInput(string.join(errors, ", ")))
  }
}

/// Update an existing todo using shared types
pub fn update_todo(
  store: Store,
  id: String,
  input: UpdateTodoInput,
) -> Result(Todo, shared.AppError) {
  let changes = []
  let changes = case input.title {
    Some(t) -> [#("title", t), ..changes]
    None -> changes
  }
  let changes = case input.description {
    Some(d) -> [#("description", d), ..changes]
    None -> changes
  }
  let changes = case input.completed {
    Some(c) -> [#("completed", bool_to_string(c)), ..changes]
    None -> changes
  }

  case update_api(store, id, changes) {
    UpdateOkResult(todo) -> Ok(todo)
    UpdateErrorResult(NotFoundUpdate) -> Error(NotFound("Todo not found: " <> id))
    UpdateErrorResult(ValidationErrorUpdate(errors)) ->
      Error(shared.InvalidInput(string.join(errors, ", ")))
  }
}

fn bool_to_string(b: Bool) -> String {
  case b {
    True -> "true"
    False -> "false"
  }
}

@external(erlang, "string", "join")
fn string_join(list: List(String), separator: String) -> String
