import frontend/effects
import frontend/model as m
import frontend/model.{type Filter, type LoadingState, type Model}
import frontend/msg.{type Msg}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared.{type Todo}

/// Main update function handling all messages
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Initial load
    msg.LoadTodos -> #(
      m.Model(..model, loading: m.Loading),
      effects.fetch_todos(),
    )

    msg.TodosLoaded(todos) -> #(
      m.Model(..model, todos: todos, loading: m.Loaded),
      effect.none(),
    )

    msg.TodosLoadFailed(error) -> #(
      m.Model(..model, loading: m.Error(error)),
      effect.none(),
    )

    // Create todo flow
    msg.SubmitNewTodo -> {
      case model.new_todo_title {
        "" -> #(model, effect.none())
        _ -> {
          let title = model.new_todo_title
          let description = case model.new_todo_description {
            "" -> None
            d -> Some(d)
          }
          #(model, effects.create_todo(title, description))
        }
      }
    }

    msg.CreateTodo -> {
      case model.new_todo_title {
        "" -> #(model, effect.none())
        _ -> {
          let description = case model.new_todo_description {
            "" -> None
            d -> Some(d)
          }
          #(model, effects.create_todo(model.new_todo_title, description))
        }
      }
    }

    msg.TodoCreated(new_todo) -> {
      let updated_todos = [new_todo, ..model.todos]
      #(m.Model(
        ..model,
        todos: updated_todos,
        new_todo_title: "",
        new_todo_description: "",
      ), effect.none())
    }

    msg.TodoCreateFailed(_error) -> #(model, effect.none())

    // Form input handling
    msg.UpdateNewTodoTitle(title) -> #(
      m.Model(..model, new_todo_title: title),
      effect.none(),
    )

    msg.UpdateNewTodoDescription(desc) -> #(
      m.Model(..model, new_todo_description: desc),
      effect.none(),
    )

    // Toggle completion
    msg.ToggleTodo(id, completed) -> {
      case find_todo_by_id(model.todos, id) {
        Some(existing) -> {
          let priority = existing.priority
          let title = existing.title
          let description = existing.description
          #(model, effects.update_todo(id, title, description, priority, completed))
        }
        None -> #(model, effect.none())
      }
    }

    msg.TodoUpdated(updated_todo) -> {
      let updated_todos = list.map(model.todos, fn(t) {
        case t.id == updated_todo.id {
          True -> updated_todo
          False -> t
        }
      })
      #(m.Model(..model, todos: updated_todos), effect.none())
    }

    msg.TodoUpdateFailed(_error) -> #(model, effect.none())

    // Delete todo
    msg.DeleteTodo(id) -> #(model, effects.delete_todo(id))

    msg.TodoDeleted(id) -> {
      let updated_todos = list.filter(model.todos, fn(t) { t.id != id })
      #(m.Model(..model, todos: updated_todos), effect.none())
    }

    msg.TodoDeleteFailed(_error) -> #(model, effect.none())

    // Filter selection
    msg.SetFilter(filter) -> #(m.Model(..model, filter: filter), effect.none())
  }
}

/// Find a todo by ID in the list
fn find_todo_by_id(todos: List(Todo), id: String) -> Option(Todo) {
  case list.find(todos, fn(t) { t.id == id }) {
    Ok(todo_item) -> Some(todo_item)
    Error(_) -> None
  }
}
