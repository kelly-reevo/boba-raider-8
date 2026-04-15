import counter.{type CounterMsg}
import gleam/erlang/process.{type Subject}

pub type Context {
  Context(counter: Subject(CounterMsg), static_directory: String)
}
