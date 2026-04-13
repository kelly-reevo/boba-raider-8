import frontend/model.{type Model, Todo, Idle, Model as ModelConstructor}
import frontend/msg.{type Msg}
import frontend/update
import frontend/view
import lustre
import lustre/effect.{type Effect}
import gleam/option.{None}

pub fn main() {
  let app = lustre.application(init, update.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  // Initialize with sample todos for testing delete functionality
  let sample_todos = [
    Todo(id: "1", title: "Buy groceries", priority: "high", completed: False),
    Todo(id: "2", title: "Walk the dog", priority: "medium", completed: False),
    Todo(id: "3", title: "Read a book", priority: "low", completed: True),
  ]

  #(
    ModelConstructor(
      todos: sample_todos,
      loading_state: Idle,
      deleting_id: None,
    ),
    effect.none()
  )
}
