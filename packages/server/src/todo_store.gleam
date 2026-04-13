import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/string
import shared

pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
    created_at: Int,
    updated_at: Int,
  )
}

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

type StoreMsg {
  Create(payload: List(#(String, String)), reply: Subject(CreateResult))
  Get(id: String, reply: Subject(GetResult))
  Update(id: String, changes: List(#(String, String)), reply: Subject(UpdateResult))
  Delete(id: String, reply: Subject(DeleteResult))
  ListAll(filter: String, reply: Subject(ListResult))
}

type StoreState {
  StoreState(todos: Dict(String, Todo), next_id: Int)
}

pub opaque type Store {
  Store(Subject(StoreMsg))
}

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

fn pad_left(s: String, length: Int, pad_char: String) -> String {
  case string.length(s) >= length {
    True -> s
    False -> pad_left(pad_char <> s, length, pad_char)
  }
}

fn generate_id(counter: Int) -> String {
  let now = current_timestamp_millis()

  let part1 = pad_left(int.to_string(counter), 8, "0")
  let part2 = string.slice(pad_left(int.to_string(now), 12, "0"), 0, 4)
  let part3 = string.slice(pad_left(int.to_string(now / 10), 12, "0"), 0, 4)
  let part4 = string.slice(pad_left(int.to_string(now / 100), 12, "0"), 0, 4)
  let part5_source = int.to_string(now / 1000) <> int.to_string(counter)
  let part5 = string.slice(pad_left(part5_source, 12, "0"), 0, 12)

  part1 <> "-" <> part2 <> "-" <> part3 <> "-" <> part4 <> "-" <> part5
}

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

    ListAll(filter, reply) -> {
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
        Some("") -> None
        Some(d) -> Some(d)
        None -> None
      }
      let priority = case get_field(payload, "priority") {
        Some("high") -> "high"
        Some("medium") -> "medium"
        Some("low") -> "low"
        _ -> "medium"
      }
      let now = current_timestamp_millis()

      let new_item = Todo(
        id: id,
        title: title,
        description: description,
        priority: priority,
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
            Some("") -> None
            Some(d) -> Some(d)
            None -> existing.description
          }
          let priority = case get_field(changes, "priority") {
            Some("low") -> "low"
            Some("medium") -> "medium"
            Some("high") -> "high"
            Some(_) -> existing.priority
            None -> existing.priority
          }
          let completed = case get_field(changes, "completed") {
            Some("true") -> True
            Some("false") -> False
            Some(_) -> existing.completed
            None -> existing.completed
          }

          let now = current_timestamp_millis()
          let updated = Todo(
            id: existing.id,
            title: title,
            description: description,
            priority: priority,
            completed: completed,
            created_at: existing.created_at,
            updated_at: now,
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
    Ok(_) -> DeleteOk
    Error(_) -> DeleteNotFound
  }
}

fn get_field(payload: List(#(String, String)), key: String) -> Option(String) {
  case list.find(payload, fn(field) { field.0 == key }) {
    Ok(#(_, value)) -> Some(value)
    Error(_) -> None
  }
}

fn validate_create(payload: List(#(String, String))) -> List(String) {
  let errors = []

  let errors = case get_field(payload, "title") {
    None -> ["title is required", ..errors]
    Some(t) -> {
      case string.trim(t) {
        "" -> ["title is required", ..errors]
        _ -> errors
      }
    }
  }

  list.reverse(errors)
}

fn validate_update(changes: List(#(String, String))) -> List(String) {
  let errors = []

  // Validate priority if present
  let errors = case get_field(changes, "priority") {
    Some(p) if p != "low" && p != "medium" && p != "high" && p != "" -> [
      "priority must be low, medium, or high",
      ..errors
    ]
    _ -> errors
  }

  // Validate title if present - must not be empty or whitespace-only
  let errors = case get_field(changes, "title") {
    Some(t) -> {
      case string.trim(t) {
        "" -> ["title is required", ..errors]
        _ -> errors
      }
    }
    None -> errors
  }

  list.reverse(errors)
}

@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

fn current_timestamp_millis() -> Int {
  system_time(1000)
}

fn apply_filter(todos: List(Todo), filter: String) -> List(Todo) {
  case string.lowercase(filter) {
    "all" -> todos
    "active" -> list.filter(todos, fn(t) { !t.completed })
    "completed" -> list.filter(todos, fn(t) { t.completed })
    _ -> todos
  }
}

fn sort_by_created_at_desc(todos: List(Todo)) -> List(Todo) {
  list.sort(todos, fn(a, b) {
    case int.compare(a.created_at, b.created_at) {
      order.Gt -> order.Lt
      order.Lt -> order.Gt
      order.Eq -> {
        order.reverse(string.compare)(a.id, b.id)
      }
    }
  })
}

// ============================================================================
// Public API
// ============================================================================

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

pub fn list_all(store: Store, filter: String) -> Result(List(Todo), String) {
  let Store(subject) = store
  let reply_subject = process.new_subject()
  actor.send(subject, ListAll(filter, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(ListSuccess(todos)) -> Ok(todos)
    _ -> Error("timeout")
  }
}

pub fn list_all_api(store: Store) -> List(Todo) {
  case list_all(store, "all") {
    Ok(todos) -> todos
    Error(_) -> []
  }
}

pub fn list_by_status_api(store: Store, completed: Bool) -> List(Todo) {
  let filter = case completed {
    True -> "completed"
    False -> "active"
  }
  case list_all(store, filter) {
    Ok(todos) -> todos
    Error(_) -> []
  }
}

pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, String) {
  let payload = [#("title", title), #("description", description)]
  case create_api(store, payload) {
    CreateOkResult(item) -> Ok(item)
    CreateErrorResult(ValidationErrorCreate(errors)) -> {
      case errors {
        [first, ..] -> Error(first)
        _ -> Error("validation failed")
      }
    }
  }
}

/// Update a todo using shared.UpdateTodoInput (for test compatibility)
pub fn update_todo(
  store: Store,
  id: String,
  input: shared.UpdateTodoInput,
) -> Result(Todo, String) {
  // Convert UpdateTodoInput to changes list using gleam/option types
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
    Some(True) -> [#("completed", "true"), ..changes]
    Some(False) -> [#("completed", "false"), ..changes]
    None -> changes
  }

  case update_api(store, id, list.reverse(changes)) {
    UpdateOkResult(item) -> Ok(item)
    UpdateErrorResult(NotFoundUpdate) -> Error("not found")
    UpdateErrorResult(ValidationErrorUpdate(errors)) -> {
      case errors {
        [first, ..] -> Error(first)
        _ -> Error("update failed")
      }
    }
  }
}
