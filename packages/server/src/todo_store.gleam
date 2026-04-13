/// Todo Store module - HTTP API interface for todo operations
/// Wraps the todo_actor for use in HTTP request handlers

import gleam/option.{type Option}
import models/todo_item.{type Todo}
import todo_actor.{type TodoActor}

/// Store handle wrapping the todo actor
pub type Store {
  Store(actor: TodoActor)
}

/// Start the todo store (initializes the underlying actor)
pub fn start() -> Result(Store, String) {
  case todo_actor.start() {
    Ok(actor) -> Ok(Store(actor))
    Error(err) -> Error(err)
  }
}

/// Create a new todo with the given fields
pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, String) {
  todo_actor.create(store.actor, title, description, "medium")
}

/// Read a todo by id
/// Returns Ok(Todo) if found, Error("not_found") if not found
pub fn get_todo(store: Store, id: String) -> Result(Todo, String) {
  todo_actor.read(store.actor, id)
}

/// List all todos (optionally filtered)
pub fn list_todos(store: Store, filter: todo_actor.Filter) -> List(Todo) {
  todo_actor.list(store.actor, filter)
}

/// Update an existing todo
pub fn update_todo(
  store: Store,
  id: String,
  title: Option(String),
  description: Option(String),
  priority: Option(String),
  completed: Option(Bool),
) -> Result(Todo, String) {
  todo_actor.update(store.actor, id, title, description, priority, completed)
}

/// Delete a todo by id
pub fn delete_todo(store: Store, id: String) -> Result(Nil, String) {
  todo_actor.delete(store.actor, id)
}

/// Shutdown the store and underlying actor
pub fn shutdown(store: Store) -> Nil {
  todo_actor.shutdown(store.actor)
}
