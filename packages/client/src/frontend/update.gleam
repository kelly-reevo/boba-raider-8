import frontend/model.{type Filter, type Model, Active, All, Completed, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// Update function - handles all message types
/// Client-side filtering does NOT trigger API calls (test requirement)
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Filter messages - client-side only, no API call
    msg.SetFilter(filter) -> {
      #(Model(..model, filter: filter), effect.none())
    }

    // Todo data loaded from API
    msg.TodosLoaded(todos) -> {
      #(Model(..model, todos: todos, loading: False), effect.none())
    }

    // New todo added - re-apply current filter
    msg.TodoAdded(item) -> {
      let new_todos = [item, ..model.todos]
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Legacy counter messages (maintained for compatibility)
    msg.Increment -> #(model, effect.none())
    msg.Decrement -> #(model, effect.none())
    msg.Reset -> #(model, effect.none())
  }
}

/// Helper to get filtered todos based on current filter
pub fn apply_filter(todos: List(Todo), filter: Filter) -> List(Todo) {
  case filter {
    All -> todos
    Active -> filter_by_completed(todos, False)
    Completed -> filter_by_completed(todos, True)
  }
}

fn filter_by_completed(todos: List(Todo), completed: Bool) -> List(Todo) {
  case todos {
    [] -> []
    [item, ..rest] -> {
      let filtered = filter_by_completed(rest, completed)
      case item.completed == completed {
        True -> [item, ..filtered]
        False -> filtered
      }
    }
  }
}
