import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/order
import gleam/otp/actor

/// Represents a todo item in the system
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    priority: String,
    completed: Bool,
    created_at: Int
  )
}

/// Filter options for listing todos
pub type Filter {
  All
  Completed(Bool)
}

/// Messages that can be sent to the todo actor
pub type TodoMessage {
  List(filter: Filter, reply_to: Subject(List(Todo)))
}

/// Actor state is the list of stored todos
pub type TodoState =
  List(Todo)

/// The todo actor type
pub type TodoActor =
  Subject(TodoMessage)

/// Internal message handler loop - matches the expected actor.on_message signature
fn todo_actor_loop(state: TodoState, message: TodoMessage) {
  case message {
    List(filter, reply_to) -> {
      let filtered = case filter {
        All -> state
        Completed(True) -> list.filter(state, fn(t) { t.completed })
        Completed(False) -> list.filter(state, fn(t) { !t.completed })
      }

      // Sort by created_at descending (newest first)
      let sorted = list.sort(filtered, by: fn(a, b) {
        case int.compare(a.created_at, b.created_at) {
          order.Lt -> order.Gt
          order.Eq -> order.Eq
          order.Gt -> order.Lt
        }
      })

      process.send(reply_to, sorted)
      actor.continue(state)
    }
  }
}

/// Start the todo actor with the given initial todos
pub fn start(initial_todos: List(Todo)) -> Result(TodoActor, actor.StartError) {
  let builder = actor.new(initial_todos)
  actor.on_message(builder, todo_actor_loop)
  |> actor.start()
  |> fn(result) {
    case result {
      Ok(started) -> Ok(started.data)
      Error(err) -> Error(err)
    }
  }
}

/// Send a list message to the actor and wait for response
pub fn list(actor_ref: TodoActor, filter: Filter) -> List(Todo) {
  let reply_to = process.new_subject()
  actor.send(actor_ref, List(filter, reply_to))

  case process.receive(reply_to, 1000) {
    Ok(todos) -> todos
    Error(_) -> []
  }
}
