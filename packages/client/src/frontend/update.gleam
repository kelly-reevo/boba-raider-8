import frontend/effects
import frontend/model.{type LoadingState, type Model, type Todo, Model, Error as LoadingError, Idle, Loading, Success}
import frontend/msg.{type Msg}
import gleam/dict
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Legacy counter messages - no-op since count field was removed
    msg.Increment -> #(model, effect.none())
    msg.Decrement -> #(model, effect.none())
    msg.Reset -> #(model, effect.none())

    // Loading state messages
    msg.SetListLoading(is_loading) -> {
      let new_state = case is_loading {
        True -> Loading
        False -> Idle
      }
      #(set_list_loading(model, new_state), effect.none())
    }

    msg.SetFormLoading(is_loading) -> {
      let new_state = case is_loading {
        True -> Loading
        False -> Idle
      }
      #(set_form_loading(model, new_state), effect.none())
    }

    msg.SetTodoLoading(todo_id, is_loading) -> {
      let new_state = case is_loading {
        True -> Loading
        False -> Idle
      }
      #(set_todo_loading(model, todo_id, new_state), effect.none())
    }

    msg.ClearLoadingStates -> {
      #(clear_all_loading(model), effect.none())
    }

    // Load todos flow
    msg.LoadTodosRequest -> {
      let new_model =
        model
        |> set_list_loading(Loading)
        |> clear_error()
      #(new_model, effects.fetch_todos())
    }

    msg.LoadTodosSuccess(todos) -> {
      #(set_todos(model, todos), effect.none())
    }

    msg.LoadTodosError(error) -> {
      #(set_error(model, error), effect.none())
    }

    // Submit todo flow
    msg.SubmitTodoRequest -> {
      case model.title_input {
        "" -> #(model, effect.none())
        _ -> {
          let new_model =
            model
            |> set_form_loading(Loading)
            |> clear_error()
          #(new_model, effects.submit_todo(model.title_input, model.description_input))
        }
      }
    }

    msg.SubmitTodoSuccess(new_item) -> {
      #(add_todo(model, new_item), effect.none())
    }

    msg.SubmitTodoError(error) -> {
      #(Model(..model, form_loading: LoadingError(error), error: error), effect.none())
    }

    // Toggle todo flow
    msg.ToggleTodoRequest(todo_id, completed) -> {
      let new_model = set_todo_loading(model, todo_id, Loading)
      #(new_model, effects.toggle_todo(todo_id, completed))
    }

    msg.ToggleTodoSuccess(updated_item) -> {
      #(update_todo(model, updated_item), effect.none())
    }

    msg.ToggleTodoError(error) -> {
      #(Model(..model, error: error), effect.none())
    }

    // Delete todo flow
    msg.DeleteTodoRequest(todo_id) -> {
      let new_model = set_todo_loading(model, todo_id, Loading)
      #(new_model, effects.delete_todo(todo_id))
    }

    msg.DeleteTodoSuccess(todo_id) -> {
      #(remove_todo(model, todo_id), effect.none())
    }

    msg.DeleteTodoError(error) -> {
      #(Model(..model, error: error), effect.none())
    }

    // Form input messages
    msg.TitleInputChanged(value) -> {
      #(set_title_input(model, value), effect.none())
    }

    msg.DescriptionInputChanged(value) -> {
      #(set_description_input(model, value), effect.none())
    }
  }
}

// Re-export model helper functions for local use
fn set_list_loading(m: Model, loading: LoadingState) -> Model {
  Model(..m, list_loading: loading)
}

fn set_form_loading(m: Model, loading: LoadingState) -> Model {
  Model(..m, form_loading: loading)
}

fn set_todo_loading(m: Model, todo_id: String, loading: LoadingState) -> Model {
  Model(..m, todo_loading: dict.insert(m.todo_loading, todo_id, loading))
}

fn clear_error(m: Model) -> Model {
  Model(..m, error: "")
}

fn set_error(m: Model, error: String) -> Model {
  Model(..m, error: error, list_loading: LoadingError(error))
}

fn set_todos(m: Model, todos: List(Todo)) -> Model {
  Model(..m, todos: todos, list_loading: Success)
}

fn add_todo(m: Model, item: Todo) -> Model {
  Model(..m, todos: [item, ..m.todos], form_loading: Success, title_input: "", description_input: "")
}

fn update_todo(m: Model, updated: Todo) -> Model {
  let new_todos = m.todos |> list.map(fn(t) {
    case t.id == updated.id {
      True -> updated
      False -> t
    }
  })
  let new_loading = dict.delete(m.todo_loading, updated.id)
  Model(..m, todos: new_todos, todo_loading: new_loading)
}

fn remove_todo(m: Model, todo_id: String) -> Model {
  let new_todos = m.todos |> list.filter(fn(t) { t.id != todo_id })
  let new_loading = dict.delete(m.todo_loading, todo_id)
  Model(..m, todos: new_todos, todo_loading: new_loading)
}

fn set_title_input(m: Model, value: String) -> Model {
  Model(..m, title_input: value)
}

fn set_description_input(m: Model, value: String) -> Model {
  Model(..m, description_input: value)
}

fn clear_all_loading(m: Model) -> Model {
  Model(
    ..m,
    list_loading: Idle,
    form_loading: Idle,
    todo_loading: dict.new(),
    error: "",
  )
}

import gleam/list
