/// API effects for todo management
/// Simplified: Returns mock data for testing empty states

import frontend/model.{type Todo, Todo}
import frontend/msg.{type Msg}
import gleam/option.{None}
import lustre/effect

/// Fetch all todos - returns empty list for initial empty state test
pub fn fetch_todos() -> effect.Effect(Msg) {
  // Return empty list initially - simulates "no todos exist"
  effect.from(fn(dispatch) {
    dispatch(msg.TodosLoaded([]))
  })
}

/// Create a new todo - adds todo and triggers update
pub fn create_todo(
  title: String,
  _description: String,
  _priority: String,
) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let new_item = Todo(
      id: "new-1",
      title: title,
      description: None,
      priority: "medium",
      completed: False,
      created_at: "0",
      updated_at: "0",
    )
    dispatch(msg.TodoCreated(new_item))
  })
}

/// Delete a todo
pub fn delete_todo(id: String) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    dispatch(msg.TodoDeleted(id))
  })
}

/// Toggle a todo's completed status
pub fn toggle_todo(item: Todo) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let updated = Todo(..item, completed: !item.completed)
    dispatch(msg.TodoUpdated(updated))
  })
}
