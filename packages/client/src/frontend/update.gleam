import frontend/model.{type Model}
import frontend/msg.{
  type Msg, type Status, AddTodo, DeleteTodo, Error as ErrorStatus, FetchTodos,
  SetFilter, Start, Success, ToggleTodo, UpdateDescription, UpdateTitle,
}
import lustre/effect.{type Effect}

/// Main update function handling all messages with loading state management
pub fn update(m: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // FetchTodos operation lifecycle
    FetchTodos(status, payload) -> handle_fetch_todos(m, status, payload)

    // AddTodo operation lifecycle
    AddTodo(status, payload) -> handle_add_todo(m, status, payload)

    // ToggleTodo operation lifecycle
    ToggleTodo(status, payload) -> handle_toggle_todo(m, status, payload)

    // DeleteTodo operation lifecycle
    DeleteTodo(status, payload) -> handle_delete_todo(m, status, payload)

    // SetFilter triggers a new fetch
    SetFilter(f) -> handle_set_filter(m, f)

    // Form updates (no effects)
    UpdateTitle(title) -> #(
      model.Model(..m, new_todo_title: title),
      effect.none(),
    )
    UpdateDescription(description) -> #(
      model.Model(..m, new_todo_description: description),
      effect.none(),
    )
  }
}

/// Handle FetchTodos operation lifecycle
fn handle_fetch_todos(
  m: Model,
  status: Status,
  payload: msg.FetchTodosPayload,
) -> #(Model, Effect(Msg)) {
  case status {
    Start -> #(
      model.Model(
        ..m,
        is_loading: True,
        loading_message: "Loading todos...",
        error: "",
      ),
      effect.none(),
    )

    Success -> {
      let items = case payload {
        msg.TodosList(items) -> items
        _ -> []
      }
      #(
        model.Model(
          ..m,
          todos: items,
          is_loading: False,
          loading_message: "",
          error: "",
        ),
        effect.none(),
      )
    }

    ErrorStatus(error_msg) -> #(
      model.Model(
        ..m,
        is_loading: False,
        loading_message: "",
        error: error_msg,
      ),
      effect.none(),
    )
  }
}

/// Handle AddTodo operation lifecycle
fn handle_add_todo(
  m: Model,
  status: Status,
  payload: msg.AddTodoPayload,
) -> #(Model, Effect(Msg)) {
  case status {
    Start -> #(
      model.Model(
        ..m,
        is_adding: True,
        submit_button_text: "Adding...",
        error: "",
      ),
      effect.none(),
    )

    Success -> {
      let new_item = case payload {
        msg.NewTodo(item) -> [item]
        _ -> []
      }
      #(
        model.Model(
          ..m,
          todos: list_append(m.todos, new_item),
          is_adding: False,
          submit_button_text: "Add Todo",
          new_todo_title: "",
          new_todo_description: "",
          error: "",
        ),
        effect.none(),
      )
    }

    ErrorStatus(error_msg) -> #(
      model.Model(
        ..m,
        is_adding: False,
        submit_button_text: "Add Todo",
        error: error_msg,
      ),
      effect.none(),
    )
  }
}

/// Handle ToggleTodo operation lifecycle
fn handle_toggle_todo(
  m: Model,
  status: Status,
  payload: msg.ToggleTodoPayload,
) -> #(Model, Effect(Msg)) {
  let item_id = case payload {
    msg.ToggleData(id, _) -> id
    msg.ToggledTodo(item) -> item.id
    _ -> ""
  }

  case status {
    Start -> #(
      model.Model(
        ..m,
        is_loading: True,
        loading_message: "Saving...",
        saving_todo_ids: list_append(m.saving_todo_ids, [item_id]),
        error: "",
      ),
      effect.none(),
    )

    Success -> {
      let updated_todos = case payload {
        msg.ToggledTodo(updated) -> update_todo_in_list(m.todos, updated)
        msg.ToggleData(id, completed) -> {
          case find_todo_by_id(m.todos, id) {
            Ok(existing) -> {
              let updated = shared.Todo(
                ..existing,
                completed: completed,
              )
              update_todo_in_list(m.todos, updated)
            }
            Error(_) -> m.todos
          }
        }
        _ -> m.todos
      }

      #(
        model.Model(
          ..m,
          todos: updated_todos,
          is_loading: False,
          loading_message: "",
          saving_todo_ids: list_remove(m.saving_todo_ids, item_id),
          error: "",
        ),
        effect.none(),
      )
    }

    ErrorStatus(error_msg) -> #(
      model.Model(
        ..m,
        is_loading: False,
        loading_message: "",
        saving_todo_ids: list_remove(m.saving_todo_ids, item_id),
        error: error_msg,
      ),
      effect.none(),
    )
  }
}

/// Handle DeleteTodo operation lifecycle
fn handle_delete_todo(
  m: Model,
  status: Status,
  payload: msg.DeleteTodoPayload,
) -> #(Model, Effect(Msg)) {
  let item_id = case payload {
    msg.DeleteData(id) -> id
    msg.DeleteResult(id) -> id
    _ -> ""
  }

  case status {
    Start -> #(
      model.Model(
        ..m,
        deleting_todo_ids: list_append(m.deleting_todo_ids, [item_id]),
        error: "",
      ),
      effect.none(),
    )

    Success -> {
      let remaining_todos = list_filter(m.todos, fn(t) { t.id != item_id })
      #(
        model.Model(
          ..m,
          todos: remaining_todos,
          deleting_todo_ids: list_remove(m.deleting_todo_ids, item_id),
          error: "",
        ),
        effect.none(),
      )
    }

    ErrorStatus(error_msg) -> #(
      model.Model(
        ..m,
        deleting_todo_ids: list_remove(m.deleting_todo_ids, item_id),
        error: error_msg,
      ),
      effect.none(),
    )
  }
}

/// Handle SetFilter - triggers a new fetch
fn handle_set_filter(m: Model, f: shared.Filter) -> #(Model, Effect(Msg)) {
  // Filter change shows loading state
  let new_model = model.Model(
    ..m,
    filter: f,
    is_loading: True,
    loading_message: "Loading todos...",
    error: "",
  )

  // In a real implementation, this would trigger an effect to fetch filtered todos
  // For simplicity, we immediately "succeed" with the same todos
  #(new_model, effect.none())
}

/// Helper: Find a todo by ID
fn find_todo_by_id(todos: List(shared.Todo), id: String) -> Result(shared.Todo, Nil) {
  case todos {
    [] -> Error(Nil)
    [first, ..rest] ->
      case first.id == id {
        True -> Ok(first)
        False -> find_todo_by_id(rest, id)
      }
  }
}

/// Helper: Update a todo in the list
fn update_todo_in_list(todos: List(shared.Todo), updated: shared.Todo) -> List(shared.Todo) {
  case todos {
    [] -> []
    [first, ..rest] ->
      case first.id == updated.id {
        True -> [updated, ..rest]
        False -> [first, ..update_todo_in_list(rest, updated)]
      }
  }
}

/// Helper: Append two lists
fn list_append(list: List(a), item: List(a)) -> List(a) {
  case list {
    [] -> item
    [first, ..rest] -> [first, ..list_append(rest, item)]
  }
}

/// Helper: Remove an item from a list
fn list_remove(list: List(String), item: String) -> List(String) {
  list_filter(list, fn(x) { x != item })
}

/// Helper: Filter a list
fn list_filter(list: List(a), predicate: fn(a) -> Bool) -> List(a) {
  case list {
    [] -> []
    [first, ..rest] ->
      case predicate(first) {
        True -> [first, ..list_filter(rest, predicate)]
        False -> list_filter(rest, predicate)
      }
  }
}

import shared
