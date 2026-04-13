/// Public API module for todo storage
/// Wraps the todo_actor and provides a clean interface

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import todo_actor
import models/todo_item.{type Todo}

/// Public handle for the todo store
pub type TodoStore {
  TodoStore(actor: todo_actor.TodoActor)
}

/// Start the todo store
pub fn start() -> Result(TodoStore, String) {
  case todo_actor.start() {
    Ok(actor) -> Ok(TodoStore(actor))
    Error(e) -> Error(e)
  }
}

/// Create a new todo
/// Description is converted to None if empty string
pub fn create(
  store: TodoStore,
  title: String,
  description: String,
  priority: String,
) -> Result(Todo, String) {
  todo_actor.create(store.actor, title, description, priority)
}

/// Read a todo by id
pub fn read(store: TodoStore, id: String) -> Result(Todo, String) {
  todo_actor.read(store.actor, id)
}

/// Update a todo
pub fn update(
  store: TodoStore,
  id: String,
  title: Option(String),
  description: Option(String),
  priority: Option(String),
  completed: Option(Bool),
) -> Result(Todo, String) {
  todo_actor.update(store.actor, id, title, description, priority, completed)
}

/// Delete a todo
pub fn delete(store: TodoStore, id: String) -> Result(Nil, String) {
  todo_actor.delete(store.actor, id)
}

/// Get all todos as a Dict
pub fn get_all(store: TodoStore) -> Dict(String, Todo) {
  todo_actor.get_all(store.actor)
}

/// List todos with optional filter
pub fn list(store: TodoStore, filter: todo_actor.Filter) -> List(Todo) {
  todo_actor.list(store.actor, filter)
}
