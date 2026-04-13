import config.{type Config}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import shared.{type Todo}
import todo_store.{type Store}
import web/http_server_actor
import web/router

pub type CreateResult {
  CreateOk(Todo)
  CreateValidationError(List(String))
}

pub type GetResult {
  GetOk(Todo)
  NotFoundGet
}

pub type UpdateResult {
  UpdateOk(Todo)
  NotFoundUpdate
  UpdateValidationError(List(String))
}

pub type DeleteResult {
  DeleteOk
  NotFoundDelete
}

pub type App {
  App(store: Option(Store))
}

pub type SupervisorMsg {
  StartHttp(Config)
  GetStore(reply: Subject(Option(Store)))
  CreateTodoCmd(payload: List(#(String, String)), reply: Subject(CreateResult))
  GetTodoCmd(id: String, reply: Subject(GetResult))
  UpdateTodoCmd(id: String, changes: List(#(String, String)), reply: Subject(UpdateResult))
  DeleteTodoCmd(id: String, reply: Subject(DeleteResult))
}

pub type Supervisor =
  Subject(SupervisorMsg)

pub fn start(cfg: Config) -> Result(Supervisor, String) {
  case todo_store.start() {
    Ok(store) -> {
      let state = App(store: Some(store))

      case
        actor.new(state)
        |> actor.on_message(handle_supervisor_msg)
        |> actor.start()
      {
        Ok(started) -> {
          let sup = started.data

          let handler = router.make_handler(store)
          case http_server_actor.start(cfg.port, handler) {
            Ok(_) -> Ok(sup)
            Error(_) -> Ok(sup)
          }
        }
        Error(_) -> Error("Failed to start supervisor")
      }
    }
    Error(err) -> Error("Failed to start store: " <> err)
  }
}

pub fn start_test() -> Supervisor {
  let assert Ok(store) = todo_store.start()
  let state = App(store: Some(store))

  let assert Ok(started) =
    actor.new(state)
    |> actor.on_message(handle_supervisor_msg)
    |> actor.start()

  started.data
}

fn handle_supervisor_msg(
  state: App,
  msg: SupervisorMsg,
) -> actor.Next(App, SupervisorMsg) {
  case msg {
    StartHttp(_cfg) -> {
      actor.continue(state)
    }

    GetStore(reply) -> {
      process.send(reply, state.store)
      actor.continue(state)
    }

    CreateTodoCmd(payload, reply) -> {
      case state.store {
        Some(store) -> {
          let result = case todo_store.create_api(store, payload) {
            todo_store.CreateOkResult(item) -> CreateOk(item)
            todo_store.CreateErrorResult(todo_store.ValidationErrorCreate(errors)) ->
              CreateValidationError(errors)
          }
          process.send(reply, result)
        }
        None -> {
          process.send(reply, CreateValidationError(["store not available"]))
        }
      }
      actor.continue(state)
    }

    GetTodoCmd(id, reply) -> {
      case state.store {
        Some(store) -> {
          let result = case todo_store.get_api(store, id) {
            todo_store.GetOkResult(item) -> GetOk(item)
            todo_store.GetErrorResult(_) -> NotFoundGet
          }
          process.send(reply, result)
        }
        None -> {
          process.send(reply, NotFoundGet)
        }
      }
      actor.continue(state)
    }

    UpdateTodoCmd(id, changes, reply) -> {
      case state.store {
        Some(store) -> {
          let result = case todo_store.update_api(store, id, changes) {
            todo_store.UpdateOkResult(item) -> UpdateOk(item)
            todo_store.UpdateErrorResult(todo_store.NotFoundUpdate) -> NotFoundUpdate
            todo_store.UpdateErrorResult(todo_store.ValidationErrorUpdate(errors)) ->
              UpdateValidationError(errors)
          }
          process.send(reply, result)
        }
        None -> {
          process.send(reply, NotFoundUpdate)
        }
      }
      actor.continue(state)
    }

    DeleteTodoCmd(id, reply) -> {
      case state.store {
        Some(store) -> {
          let result = case todo_store.delete_api(store, id) {
            todo_store.DeleteOkResult -> DeleteOk
            todo_store.DeleteErrorResult(_) -> NotFoundDelete
          }
          process.send(reply, result)
        }
        None -> {
          process.send(reply, NotFoundDelete)
        }
      }
      actor.continue(state)
    }
  }
}

// Public API for test interactions

pub fn create_todo(
  app: Supervisor,
  payload: List(#(String, String)),
) -> Result(Todo, CreateError) {
  let reply = process.new_subject()
  process.send(app, CreateTodoCmd(payload, reply))

  case process.receive(reply, 5000) {
    Ok(CreateOk(item)) -> Ok(item)
    Ok(CreateValidationError(errors)) -> Error(ValidationError(errors))
    _ -> Error(ValidationError(["timeout"]))
  }
}

pub type CreateError {
  ValidationError(List(String))
}

pub fn get_todo(app: Supervisor, id: String) -> Result(Todo, GetError) {
  let reply = process.new_subject()
  process.send(app, GetTodoCmd(id, reply))

  case process.receive(reply, 5000) {
    Ok(GetOk(item)) -> Ok(item)
    Ok(NotFoundGet) -> Error(NotFound)
    _ -> Error(NotFound)
  }
}

pub type GetError {
  NotFound
}

pub fn update_todo(
  app: Supervisor,
  id: String,
  changes: List(#(String, String)),
) -> Result(Todo, UpdateError) {
  let reply = process.new_subject()
  process.send(app, UpdateTodoCmd(id, changes, reply))

  case process.receive(reply, 5000) {
    Ok(UpdateOk(item)) -> Ok(item)
    Ok(NotFoundUpdate) -> Error(NotFoundUpdateError)
    Ok(UpdateValidationError(errors)) -> Error(ValidationErrorUpdate(errors))
    _ -> Error(NotFoundUpdateError)
  }
}

pub type UpdateError {
  NotFoundUpdateError
  ValidationErrorUpdate(List(String))
}

pub fn delete_todo(app: Supervisor, id: String) -> Result(Nil, DeleteError) {
  let reply = process.new_subject()
  process.send(app, DeleteTodoCmd(id, reply))

  case process.receive(reply, 5000) {
    Ok(DeleteOk) -> Ok(Nil)
    Ok(NotFoundDelete) -> Error(NotFoundDeleteError)
    _ -> Error(NotFoundDeleteError)
  }
}

pub type DeleteError {
  NotFoundDeleteError
}
