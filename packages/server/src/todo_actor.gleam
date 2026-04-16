import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/list
import gleam/option.{type Option}
import gleam/result
import shared.{type AppError, type Priority, type Todo, NotFound, Todo}
import shared/todo_validation.{type TodoPatch}

/// Messages supported by the todo actor
pub type TodoMsg {
  CreateTodo(
    title: String,
    description: Option(String),
    priority: Priority,
    reply_with: Subject(Todo),
  )
  GetAllTodos(reply_with: Subject(List(Todo)))
  GetTodoById(id: String, reply_with: Subject(Result(Todo, AppError)))
  UpdateTodo(
    id: String,
    changes: TodoPatch,
    reply_with: Subject(Result(Todo, AppError)),
  )
  DeleteTodo(id: String, reply_with: Subject(Result(Bool, AppError)))
}

/// Start the todo actor with empty state
pub fn start() -> Result(Subject(TodoMsg), actor.StartError) {
  let result =
    actor.new([])
    |> actor.on_message(handle_message)
    |> actor.start()
  case result {
    Ok(started) -> Ok(started.data)
    Error(err) -> Error(err)
  }
}

fn handle_message(
  todos: List(Todo),
  msg: TodoMsg,
) -> actor.Next(List(Todo), TodoMsg) {
  case msg {
    CreateTodo(title, description, priority, reply_with) -> {
      let new_todo = create_new_todo(title, description, priority)
      process.send(reply_with, new_todo)
      actor.continue([new_todo, ..todos])
    }
    GetAllTodos(reply_with) -> {
      process.send(reply_with, list.reverse(todos))
      actor.continue(todos)
    }
    GetTodoById(id, reply_with) -> {
      let result = find_todo_by_id(todos, id)
      process.send(reply_with, result)
      actor.continue(todos)
    }
    UpdateTodo(id, changes, reply_with) -> {
      let result = update_todo_in_list(todos, id, changes)
      case result {
        Ok(#(updated_todo, updated_list)) -> {
          process.send(reply_with, Ok(updated_todo))
          actor.continue(updated_list)
        }
        Error(err) -> {
          process.send(reply_with, Error(err))
          actor.continue(todos)
        }
      }
    }
    DeleteTodo(id, reply_with) -> {
      let result = delete_todo_from_list(todos, id)
      case result {
        Ok(updated_list) -> {
          process.send(reply_with, Ok(True))
          actor.continue(updated_list)
        }
        Error(err) -> {
          process.send(reply_with, Error(err))
          actor.continue(todos)
        }
      }
    }
  }
}

fn create_new_todo(
  title: String,
  description: Option(String),
  priority: Priority,
) -> Todo {
  let id = generate_uuid()
  Todo(id: id, title: title, description: description, priority: priority, completed: False)
}

@external(erlang, "server_ffi", "generate_uuid")
fn generate_uuid() -> String

fn find_todo_by_id(todos: List(Todo), id: String) -> Result(Todo, AppError) {
  list.find(todos, fn(t) { t.id == id })
  |> result.replace_error(NotFound)
}

fn update_todo_in_list(
  todos: List(Todo),
  id: String,
  changes: TodoPatch,
) -> Result(#(Todo, List(Todo)), AppError) {
  case find_todo_by_id(todos, id) {
    Ok(existing) -> {
      let updated = apply_patch(existing, changes)
      let updated_list = list.map(todos, fn(t) {
        case t.id == id {
          True -> updated
          False -> t
        }
      })
      Ok(#(updated, updated_list))
    }
    Error(err) -> Error(err)
  }
}

fn apply_patch(item: Todo, patch: TodoPatch) -> Todo {
  Todo(
    id: item.id,
    title: option.unwrap(patch.title, item.title),
    description: item.description,
    priority: item.priority,
    completed: option.unwrap(patch.completed, item.completed),
  )
}

fn delete_todo_from_list(
  todos: List(Todo),
  id: String,
) -> Result(List(Todo), AppError) {
  case find_todo_by_id(todos, id) {
    Ok(_) -> Ok(list.filter(todos, fn(t) { t.id != id }))
    Error(err) -> Error(err)
  }
}

/// Public API: Create a new todo
pub fn create_todo(
  subject: Subject(TodoMsg),
  title: String,
  description: Option(String),
  priority: Priority,
) -> Todo {
  process.call(subject, 5000, CreateTodo(title, description, priority, _))
}

/// Public API: Get all todos
pub fn get_all_todos(subject: Subject(TodoMsg)) -> List(Todo) {
  process.call(subject, 5000, GetAllTodos)
}

/// Public API: Get a todo by ID
pub fn get_todo(
  subject: Subject(TodoMsg),
  id: String,
) -> Result(Todo, AppError) {
  process.call(subject, 5000, GetTodoById(id, _))
}

/// Public API: Update a todo
pub fn update_todo(
  subject: Subject(TodoMsg),
  id: String,
  changes: TodoPatch,
) -> Result(Todo, AppError) {
  process.call(subject, 5000, UpdateTodo(id, changes, _))
}

/// Public API: Delete a todo
pub fn delete_todo(
  subject: Subject(TodoMsg),
  id: String,
) -> Result(Bool, AppError) {
  process.call(subject, 5000, DeleteTodo(id, _))
}
