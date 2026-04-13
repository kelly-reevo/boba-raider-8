import frontend/effects
import frontend/model.{type Model, Model, All, Active, Completed}
import frontend/msg.{type Msg, FilterChanged, TodosLoaded, TodosLoadFailed, TodoCreated, TodoCreateFailed}
import lustre/effect.{type Effect}

/// Update function for the MVU architecture
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Filter changed: update filter and fetch filtered todos
    FilterChanged(new_filter) -> {
      let new_model = Model(..model, filter: new_filter, loading: True, error: "")
      #(new_model, effects.fetch_todos(new_filter))
    }

    // Todos loaded successfully
    TodosLoaded(todos) -> {
      #(Model(..model, todos: todos, loading: False), effect.none())
    }

    // Todos failed to load
    TodosLoadFailed(error) -> {
      #(Model(..model, loading: False, error: error), effect.none())
    }

    // New todo created - only add if it matches current filter
    TodoCreated(new_todo) -> {
      let matches_filter = case model.filter {
        All -> True
        Active -> !new_todo.completed
        Completed -> new_todo.completed
      }

      let new_todos = case matches_filter {
        True -> [new_todo, ..model.todos]
        False -> model.todos
      }

      #(Model(..model, todos: new_todos), effect.none())
    }

    // Todo creation failed
    TodoCreateFailed(_) -> {
      #(model, effect.none())
    }
  }
}
