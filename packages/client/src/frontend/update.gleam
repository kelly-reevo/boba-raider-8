import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import gleam/list
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Delete item initiated - set loading and make API call
    msg.DeleteTodo(id) -> #(
      Model(..model, loading: True, error: ""),
      effects.delete_todo(id),
    )

    // Delete successful - remove from model.todos
    msg.DeleteTodoSuccess(id) -> #(
      Model(
        todos: list.filter(model.todos, fn(item) { item.id != id }),
        loading: False,
        error: "",
      ),
      effect.none(),
    )

    // Delete error - show error message, keep todos
    msg.DeleteTodoError(error_msg) -> #(
      Model(..model, loading: False, error: error_msg),
      effect.none(),
    )

    // Load todos on init
    msg.LoadTodos -> #(model, effects.fetch_todos())

    // Todos loaded successfully
    msg.TodosLoaded(todos) -> #(
      Model(..model, todos: todos, loading: False),
      effect.none(),
    )

    // Error loading todos
    msg.TodosLoadError(error_msg) -> #(
      Model(..model, error: error_msg, loading: False),
      effect.none(),
    )
  }
}
