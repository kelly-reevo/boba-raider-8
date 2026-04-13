import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type CounterMsg {
  GetCount(reply_with: Subject(Int))
  Increment(reply_with: Subject(Int))
  Decrement(reply_with: Subject(Int))
  Reset(reply_with: Subject(Int))
}

pub fn start() -> Result(Subject(CounterMsg), actor.StartError) {
  let result =
    actor.new(0)
    |> actor.on_message(handle_message)
    |> actor.start()
  case result {
    Ok(started) -> Ok(started.data)
    Error(err) -> Error(err)
  }
}

fn handle_message(
  count: Int,
  msg: CounterMsg,
) -> actor.Next(Int, CounterMsg) {
  case msg {
    GetCount(reply_with) -> {
      process.send(reply_with, count)
      actor.continue(count)
    }
    Increment(reply_with) -> {
      let new_count = count + 1
      process.send(reply_with, new_count)
      actor.continue(new_count)
    }
    Decrement(reply_with) -> {
      let new_count = count - 1
      process.send(reply_with, new_count)
      actor.continue(new_count)
    }
    Reset(reply_with) -> {
      process.send(reply_with, 0)
      actor.continue(0)
    }
  }
}

pub fn get_count(counter: Subject(CounterMsg)) -> Int {
  process.call(counter, 5000, GetCount)
}

pub fn increment(counter: Subject(CounterMsg)) -> Int {
  process.call(counter, 5000, Increment)
}

pub fn decrement(counter: Subject(CounterMsg)) -> Int {
  process.call(counter, 5000, Decrement)
}

pub fn reset(counter: Subject(CounterMsg)) -> Int {
  process.call(counter, 5000, Reset)
}
