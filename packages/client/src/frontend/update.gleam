/// State updates with comprehensive error handling AND filter support

import frontend/effects
import frontend/model.{type ApiError, type Model, type Todo, Model, ValidationError}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Legacy counter messages (keep for compatibility)
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Load todos (legacy path)
    msg.LoadTodos -> #(
      Model(..model, loading: True, list_error: None),
      effects.load_todos()
    )
    msg.LoadTodosSuccess(todos) -> #(
      Model(..model, todos: todos, loading: False, list_error: None, global_error: None),
      effect.none()
    )
    msg.LoadTodosError(error) -> #(
      Model(..model, loading: False, list_error: Some(error), global_error: None),
      effect.none()
    )

    // Filter messages with error handling
    msg.FilterChanged(filter) -> #(
      Model(..model, current_filter: filter, loading: True, list_error: None, global_error: None),
      effects.list_todos(filter),
    )
    msg.TodosLoaded(result) -> {
      case result {
        Ok(todos) -> #(Model(..model, todos: todos, loading: False, list_error: None, global_error: None), effect.none())
        Error(err) -> #(Model(..model, loading: False, list_error: Some(model.NetworkError(err)), global_error: None), effect.none())
      }
    }

    // Form field updates
    msg.UpdateTitle(title) -> #(Model(..model, form_title: title), effect.none())
    msg.UpdateDescription(desc) -> #(Model(..model, form_description: desc), effect.none())
    msg.UpdatePriority(priority) -> #(Model(..model, form_priority: priority), effect.none())

    // Submit todo
    msg.SubmitTodo -> #(
      Model(..model, loading: True, form_errors: [], global_error: None),
      effects.submit_todo(model.form_title, model.form_description, model.form_priority)
    )
    msg.SubmitTodoSuccess(todo_item) -> #(
      Model(
        ..model,
        todos: list.append(model.todos, [todo_item]),
        loading: False,
        form_title: "",
        form_description: "",
        form_priority: "medium",
        form_errors: [],
        global_error: None,
      ),
      effect.none()
    )
    msg.SubmitTodoError(error) -> #(
      Model(
        ..model,
        loading: False,
        form_errors: case error {
          ValidationError(errors) -> errors
          _ -> []
        },
        global_error: case error {
          ValidationError(_) -> None
          _ -> Some(error)
        },
      ),
      effect.none()
    )

    // Delete todo
    msg.DeleteTodo(id) -> #(model, effects.delete_todo(id))
    msg.DeleteTodoSuccess(id) -> #(
      Model(
        ..model,
        todos: list.filter(model.todos, fn(t) { t.id != id }),
        global_error: None,
      ),
      effect.none()
    )
    msg.DeleteTodoError(error) -> #(
      Model(..model, global_error: Some(error)),
      effect.none()
    )

    // Edit todo (placeholder)
    msg.EditTodo(_id) -> #(model, effect.none())
    msg.EditTodoSuccess(_todo_item) -> #(model, effect.none())
    msg.EditTodoError(error) -> #(
      Model(..model, global_error: Some(error)),
      effect.none()
    )

    // Error handling
    msg.ClearErrors -> #(
      Model(
        ..model,
        form_errors: [],
        list_error: None,
        global_error: None,
      ),
      effect.none()
    )
    msg.RetryLoadTodos -> #(model, effects.load_todos())
  }
}
