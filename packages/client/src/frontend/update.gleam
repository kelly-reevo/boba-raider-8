import frontend/effects
import frontend/filter.{type TodoItem, TodoItem}
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/int
import gleam/list
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Legacy counter messages - for backward compatibility
    msg.Increment -> #(model, effects.post_increment())
    msg.Decrement -> #(model, effects.post_decrement())
    msg.Reset -> #(model, effects.post_reset())
    msg.GotCounter(Ok(_)) -> #(model, effect.none())
    msg.GotCounter(Error(_)) -> #(model, effect.none())

    // New todo messages
    msg.AddTodo -> {
      case model.input_text {
        "" -> #(model, effect.none())
        text -> {
          let now = current_timestamp()
          let new_todo = TodoItem(
            id: generate_id(model.todos),
            title: text,
            description: "",
            priority: "medium",
            completed: False,
            created_at: now,
            updated_at: now,
          )
          let new_model = Model(
            todos: [new_todo, ..model.todos],
            filter: model.filter,
            input_text: "",
          )
          #(new_model, effect.none())
        }
      }
    }

    msg.ToggleTodo(id) -> {
      let new_todos = list.map(model.todos, fn(item) {
        case item.id == id {
          True -> TodoItem(..item, completed: !item.completed)
          False -> item
        }
      })
      let new_model = Model(..model, todos: new_todos)
      #(new_model, effect.none())
    }

    msg.DeleteTodo(id) -> {
      let new_todos = list.filter(model.todos, fn(item) { item.id != id })
      let new_model = Model(..model, todos: new_todos)
      #(new_model, effect.none())
    }

    msg.SetFilter(filter) -> {
      #(Model(..model, filter: filter), effect.none())
    }

    msg.UpdateInput(text) -> {
      #(Model(..model, input_text: text), effect.none())
    }
  }
}

fn generate_id(todos: List(TodoItem)) -> String {
  let max_id = list.fold(todos, 0, fn(acc, item) {
    case parse_id(item.id) {
      num if num > acc -> num
      _ -> acc
    }
  })
  "todo-" <> int.to_string(max_id + 1)
}

fn parse_id(id: String) -> Int {
  case id {
    "todo-" <> num ->
      case int.parse(num) {
        Ok(n) -> n
        Error(_) -> 0
      }
    _ -> 0
  }
}

@external(javascript, "./timestamp_ffi.mjs", "now")
fn current_timestamp() -> String
