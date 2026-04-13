/// Todo store module - thin wrapper around todo_actor for API compatibility

import actors/todo_actor

/// Re-export the actor start function as todo_store.start
pub fn start() {
  todo_actor.start()
}

/// Re-export create function
pub fn create_todo(actor, title: String, description: String) {
  todo_actor.create(
    actor,
    todo_actor.CreateTodoData(title, description, "medium", False),
  )
}
