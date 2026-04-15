/// Todo application entry point with extensible initialization

import frontend/todo_effects
import frontend/todo_model.{type TodoModel}
import frontend/todo_msg.{type TodoMsg}
import frontend/todo_update
import frontend/todo_view
import lustre
import lustre/effect.{type Effect}

/// Initialize and start the todo application
pub fn main() {
  let app = lustre.application(init, todo_update.update, todo_view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

/// Initial model and effect
fn init(_flags: Nil) -> #(TodoModel, Effect(TodoMsg)) {
  #(todo_model.default(), todo_effects.fetch_todos())
}
