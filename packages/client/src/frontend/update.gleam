/// Update logic for todo application

import frontend/effects
import frontend/model.{type Model, Model, type Todo, FormState}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, Some, None}
import lustre/effect.{type Effect}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Todos loaded from API
    msg.TodosLoaded(todos) -> {
      #(Model(..model, todos: todos, loading: False, error: None), effect.none())
    }

    // Failed to load todos
    msg.TodosLoadFailed(error) -> {
      #(Model(..model, loading: False, error: Some(error)), effect.none())
    }

    // Filter changed
    msg.SetFilter(filter) -> {
      #(Model(..model, filter: filter), effect.none())
    }

    // Form input changes
    msg.SetTitle(title) -> {
      let new_form = FormState(..model.form, title: title)
      #(Model(..model, form: new_form), effect.none())
    }

    msg.SetDescription(desc) -> {
      let new_form = FormState(..model.form, description: desc)
      #(Model(..model, form: new_form), effect.none())
    }

    msg.SetPriority(priority) -> {
      let new_form = FormState(..model.form, priority: priority)
      #(Model(..model, form: new_form), effect.none())
    }

    // Submit form to create todo
    msg.SubmitForm -> {
      let title = model.form.title
      let desc = model.form.description
      let priority = model.form.priority

      case title {
        "" -> #(Model(..model, error: Some("Title is required")), effect.none())
        _ -> {
          let new_model = Model(
            ..model,
            form: FormState("", "", "medium"),
            error: None,
          )
          #(new_model, effects.create_todo(title, desc, priority))
        }
      }
    }

    // Todo created successfully
    msg.TodoCreated(item) -> {
      let new_todos = [item, ..model.todos]
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Failed to create todo
    msg.TodoCreateFailed(error) -> {
      #(Model(..model, error: Some(error)), effect.none())
    }

    // Delete todo requested
    msg.DeleteTodo(id) -> {
      #(model, effects.delete_todo(id))
    }

    // Todo deleted successfully
    msg.TodoDeleted(id) -> {
      let new_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Failed to delete todo
    msg.TodoDeleteFailed(error) -> {
      #(Model(..model, error: Some(error)), effect.none())
    }

    // Toggle todo requested
    msg.ToggleTodo(id) -> {
      case find_todo(model.todos, id) {
        Some(item) -> #(model, effects.toggle_todo(item))
        None -> #(model, effect.none())
      }
    }

    // Todo updated successfully
    msg.TodoUpdated(updated) -> {
      let new_todos = list.map(model.todos, fn(t) {
        case t.id == updated.id {
          True -> updated
          False -> t
        }
      })
      #(Model(..model, todos: new_todos), effect.none())
    }

    // Failed to update todo
    msg.TodoUpdateFailed(error) -> {
      #(Model(..model, error: Some(error)), effect.none())
    }
  }
}

fn find_todo(todos: List(Todo), id: String) -> Option(Todo) {
  case todos {
    [] -> None
    [item, ..rest] -> {
      case item.id == id {
        True -> Some(item)
        False -> find_todo(rest, id)
      }
    }
  }
}
