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

import gleam/int
import gleam/bytes

fn create_new_todo(
  title: String,
  description: Option(String),
  priority: Priority,
) -> Todo {
  let id = generate_uuid()
  Todo(id: id, title: title, description: description, priority: priority, completed: False)
}

/// Generate a random UUID v4 string (8-4-4-4-12 format)
fn generate_uuid() -> String {
  // Generate 16 random bytes for UUID v4
  let bytes_list = [
    random_byte(), random_byte(), random_byte(), random_byte(),
    random_byte(), random_byte(), random_byte(), random_byte(),
    // Version 4 UUID: first 4 bits of 7th byte must be 0100 (0x40)
    int.bitwise_or(int.bitwise_and(random_byte(), 0x0F), 0x40),
    random_byte(),
    // Variant: first 2 bits of 9th byte must be 10 (0x80-0xBF)
    int.bitwise_or(int.bitwise_and(random_byte(), 0x3F), 0x80),
    random_byte(), random_byte(), random_byte(),
    random_byte(), random_byte(), random_byte(), random_byte(),
    random_byte(), random_byte(),
  ]

  format_uuid(bytes_list)
}

fn random_byte() -> Int {
  // Use crypto:strong_rand_bytes via FFI or fall back to system time + pid hash
  // For simplicity, we'll use a basic random byte generator
  let now = erlang_system_time_microsecond()
  let pid = erlang_self()
  int.bitwise_and(now + pid, 0xFF)
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_microsecond() -> Int

@external(erlang, "erlang", "phash2")
fn erlang_self_hash() -> Int

fn erlang_self() -> Int {
  erlang_self_hash()
}

fn format_uuid(bytes: List(Int)) -> String {
  case bytes {
    [b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16] -> {
      byte_to_hex(b1) <> byte_to_hex(b2) <> byte_to_hex(b3) <> byte_to_hex(b4) <> "-" <>
      byte_to_hex(b5) <> byte_to_hex(b6) <> "-" <>
      byte_to_hex(b7) <> byte_to_hex(b8) <> "-" <>
      byte_to_hex(b9) <> byte_to_hex(b10) <> "-" <>
      byte_to_hex(b11) <> byte_to_hex(b12) <> byte_to_hex(b13) <>
      byte_to_hex(b14) <> byte_to_hex(b15) <> byte_to_hex(b16)
    }
    _ -> "00000000-0000-0000-0000-000000000000"
  }
}

fn byte_to_hex(byte: Int) -> String {
  let high_nibble = int.bitwise_shift_right(byte, 4) && 0xF
  let low_nibble = byte && 0xF
  nibble_to_hex_char(high_nibble) <> nibble_to_hex_char(low_nibble)
}

fn nibble_to_hex_char(nibble: Int) -> String {
  case nibble {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    10 -> "a"
    11 -> "b"
    12 -> "c"
    13 -> "d"
    14 -> "e"
    15 -> "f"
    _ -> "0"
  }
}

// Bitwise AND operator
fn &&(a: Int, b: Int) -> Int {
  int.bitwise_and(a, b)
}

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
    description: option.or(patch.description, item.description),
    priority: option.unwrap(patch.priority, item.priority),
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
