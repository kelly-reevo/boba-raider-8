import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import todo_item.{type TodoItem}

pub type DeleteResult {
  DeleteSuccess(Bool)
  DeleteNotFound
}

pub type TodoActorMsg {
  GetAll(reply_to: Subject(List(#(String, TodoItem))))
  Get(id: String, reply_to: Subject(Option(TodoItem)))
  Put(id: String, item: TodoItem)
  Delete(id: String, reply_to: Subject(DeleteResult))
}

pub type TodoActor =
  Subject(TodoActorMsg)

type State =
  Dict(String, TodoItem)

pub fn start() -> Result(TodoActor, actor.StartError) {
  let initial_state = dict.new()

  let assert Ok(started) =
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()

  Ok(started.data)
}

fn handle_message(state: State, msg: TodoActorMsg) -> actor.Next(State, TodoActorMsg) {
  case msg {
    GetAll(reply_to) -> {
      let items = dict.to_list(state)
      process.send(reply_to, items)
      actor.continue(state)
    }

    Get(id, reply_to) -> {
      let item = todo_item.to_option(dict.get(state, id))
      process.send(reply_to, item)
      actor.continue(state)
    }

    Put(id, item) -> {
      let new_state = dict.insert(state, id, item)
      actor.continue(new_state)
    }

    Delete(id, reply_to) -> {
      case dict.has_key(state, id) {
        True -> {
          let new_state = dict.delete(state, id)
          process.send(reply_to, DeleteSuccess(True))
          actor.continue(new_state)
        }
        False -> {
          process.send(reply_to, DeleteNotFound)
          actor.continue(state)
        }
      }
    }
  }
}
