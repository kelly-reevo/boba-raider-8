import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string

pub type Todo {
  Todo(
    id: String,
    title: String,
    description: Option(String),
    priority: String,
    completed: Bool,
  )
}

pub type CreateResult {
  CreateSuccess(Todo)
  CreateValidationError(List(String))
}

pub type GetResult {
  GetSuccess(Todo)
  GetNotFound
}

pub type UpdateResult {
  UpdateSuccess(Todo)
  UpdateNotFound
  UpdateValidationError(List(String))
}

pub type DeleteResult {
  DeleteOk
  DeleteNotFound
}

pub type StoreMsg {
  Create(payload: List(#(String, String)), reply: Subject(CreateResult))
  Get(id: String, reply: Subject(GetResult))
  Update(id: String, changes: List(#(String, String)), reply: Subject(UpdateResult))
  Delete(id: String, reply: Subject(DeleteResult))
  ListAll(reply: Subject(List(Todo)))
  ListByStatus(completed: Bool, reply: Subject(List(Todo)))
}

pub type StoreState {
  StoreState(todos: Dict(String, Todo), counter: Int)
}

pub type Store =
  Subject(StoreMsg)

fn generate_id(counter: Int) -> String {
  let base = int.to_string(counter)
  let time = process.subject_owner(process.new_subject())
  let pid_str = string.inspect(time)
  let combined = base <> pid_str

  let hex_base = string.replace(combined, "#", "")
    |> string.replace("<", "")
    |> string.replace(">", "")
    |> string.replace(".", "")

  let padded = case string.length(hex_base) >= 32 {
    True -> string.slice(hex_base, 0, 32)
    False -> hex_base <> string.repeat("0", 32 - string.length(hex_base))
  }

  string.slice(padded, 0, 8)
  <> "-"
  <> string.slice(padded, 8, 4)
  <> "-"
  <> string.slice(padded, 12, 4)
  <> "-"
  <> string.slice(padded, 16, 4)
  <> "-"
  <> string.slice(padded, 20, 12)
}

pub fn start() -> Result(Store, String) {
  let initial_state = StoreState(todos: dict.new(), counter: 0)

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start store actor")
  }
}

fn handle_message(
  state: StoreState,
  msg: StoreMsg,
) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    Create(payload, reply) -> {
      let id = generate_id(state.counter)
      let result = do_create(payload, id)
      process.send(reply, result)
      case result {
        CreateSuccess(item) -> {
          let new_todos = dict.insert(state.todos, item.id, item)
          actor.continue(StoreState(todos: new_todos, counter: state.counter + 1))
        }
        CreateValidationError(_) -> actor.continue(StoreState(..state, counter: state.counter + 1))
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
          actor.continue(StoreState(todos: new_todos, counter: state.counter))
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
          actor.continue(StoreState(todos: new_todos, counter: state.counter))
        }
        DeleteNotFound -> actor.continue(state)
      }
    }

    ListAll(reply) -> {
      let todos = dict.values(state.todos)
      process.send(reply, todos)
      actor.continue(state)
    }

    ListByStatus(completed, reply) -> {
      let todos = dict.values(state.todos)
        |> list.filter(fn(t) { t.completed == completed })
      process.send(reply, todos)
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
        desc -> desc
      }
      let priority = case get_field(payload, "priority") {
        Some(p) if p == "low" || p == "medium" || p == "high" -> p
        _ -> "medium"
      }

      let new_item = Todo(
        id: id,
        title: title,
        description: description,
        priority: priority,
        completed: False,
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

          let updated = Todo(
            id: existing.id,
            title: title,
            description: description,
            priority: priority,
            completed: completed,
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

  let errors = case get_field(changes, "priority") {
    Some(p) if p != "low" && p != "medium" && p != "high" && p != "" -> [
      "priority must be low, medium, or high",
      ..errors
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

// Public API for synchronous calls

pub fn create_api(
  store: Store,
  payload: List(#(String, String)),
) -> CreateApiResult {
  let reply_subject = process.new_subject()
  process.send(store, Create(payload, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(CreateSuccess(item)) -> CreateOkResult(item)
    Ok(CreateValidationError(errors)) -> CreateErrorResult(ValidationErrorCreate(errors))
    _ -> CreateErrorResult(ValidationErrorCreate(["timeout"]))
  }
}

pub fn get_api(store: Store, id: String) -> GetApiResult {
  let reply_subject = process.new_subject()
  process.send(store, Get(id, reply_subject))

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
  let reply_subject = process.new_subject()
  process.send(store, Update(id, changes, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(UpdateSuccess(item)) -> UpdateOkResult(item)
    Ok(UpdateNotFound) -> UpdateErrorResult(NotFoundUpdate)
    Ok(UpdateValidationError(errors)) -> UpdateErrorResult(ValidationErrorUpdate(errors))
    _ -> UpdateErrorResult(NotFoundUpdate)
  }
}

pub fn delete_api(store: Store, id: String) -> DeleteApiResult {
  let reply_subject = process.new_subject()
  process.send(store, Delete(id, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(DeleteOk) -> DeleteOkResult
    Ok(DeleteNotFound) | _ -> DeleteErrorResult(NotFoundDelete)
  }
}

pub fn list_all_api(store: Store) -> List(Todo) {
  let reply_subject = process.new_subject()
  process.send(store, ListAll(reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(todos) -> todos
    _ -> []
  }
}

pub fn list_by_status_api(store: Store, completed: Bool) -> List(Todo) {
  let reply_subject = process.new_subject()
  process.send(store, ListByStatus(completed, reply_subject))

  case process.receive(reply_subject, 5000) {
    Ok(todos) -> todos
    _ -> []
  }
}
