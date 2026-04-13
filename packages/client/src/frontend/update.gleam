import frontend/effects
import frontend/model.{type Model, Model, Loading, Loaded, Error}
import frontend/msg.{type Msg, FetchTodos, TodosLoaded, TodosLoadError, SetFilter, RetryFetch}
import lustre/effect.{type Effect}

/// Update function for MVU pattern
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    FetchTodos -> #(
      Model(..model, data_state: Loading),
      effects.fetch_todos()
    )

    TodosLoaded(todos) -> #(
      Model(..model, todos: todos, data_state: Loaded),
      effect.none()
    )

    TodosLoadError(error) -> #(
      Model(..model, data_state: Error(error)),
      effect.none()
    )

    SetFilter(filter) -> #(
      Model(..model, filter: filter),
      effect.none()
    )

    RetryFetch -> #(
      Model(..model, data_state: Loading),
      effects.fetch_todos()
    )
  }
}
