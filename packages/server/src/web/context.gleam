import counter.{type CounterMsg}
import gleam/erlang/process.{type Subject}
import todo_actor.{type TodoMsg}

pub type Context {
  Context(
    counter: Subject(CounterMsg),
    todo_subject: Subject(TodoMsg),
    static_directory: String,
  )
}
