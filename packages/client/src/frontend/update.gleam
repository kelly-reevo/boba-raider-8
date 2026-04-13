import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Form input handling
    msg.TitleChanged(title) -> {
      #(Model(..model, form_title: title), effect.none())
    }
    msg.DescriptionChanged(desc) -> {
      #(Model(..model, form_description: desc), effect.none())
    }

    // Form submission
    msg.SubmitForm -> {
      case model.form_title {
        "" -> #(Model(..model, form_error: "Title is required"), effect.none())
        _ -> {
          let eff = effects.create_todo(model.form_title, model.form_description)
          #(Model(..model, loading: True, form_error: ""), eff)
        }
      }
    }

    msg.SubmitSuccess(new_todo) -> {
      // Clear form and add new todo to list
      let updated_todos = [new_todo, ..model.todos]
      #(Model(
        todos: updated_todos,
        form_title: "",
        form_description: "",
        form_error: "",
        loading: False,
      ), effect.none())
    }

    msg.SubmitError(error) -> {
      #(Model(..model, form_error: error, loading: False), effect.none())
    }

    // Todo list management
    msg.TodosLoaded(todos) -> {
      #(Model(..model, todos: todos), effect.none())
    }

    msg.TodosLoadError(error) -> {
      #(Model(..model, form_error: error), effect.none())
    }

    // Clear error
    msg.ClearError -> {
      #(Model(..model, form_error: ""), effect.none())
    }
  }
}
