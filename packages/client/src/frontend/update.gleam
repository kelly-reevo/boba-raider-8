import frontend/api
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{Some, None}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (legacy demo)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Todo deletion flow
    msg.DeleteTodoClick(id) -> {
      // Start deletion: set loading state and call API
      #(Model(..model, deleting_id: Some(id), error: ""), api.delete_todo(id))
    }

    msg.DeleteTodoSuccess(id) -> {
      // Remove deleted todo from list and clear loading state
      let filtered = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: filtered, deleting_id: None, error: ""), effect.none())
    }

    msg.DeleteTodoFailed(error) -> {
      // Show error and clear loading state
      #(Model(..model, error: error, deleting_id: None), effect.none())
    }

    msg.ConfirmDelete(id) -> {
      // User confirmed deletion - proceed with API call
      #(Model(..model, deleting_id: Some(id), error: ""), api.delete_todo(id))
    }

    msg.CancelDelete -> {
      // User cancelled deletion - clear any pending state
      #(Model(..model, deleting_id: None), effect.none())
    }
  }
}
