/// Todo update handlers with extensible state transitions

import frontend/todo_effects
import frontend/todo_model.{type Todo, type TodoModel, TodoModel}
import frontend/todo_msg.{type TodoHttpError, type TodoMsg}
import gleam/list
import lustre/effect.{type Effect}

/// Main update function for todo messages
pub fn update(
  model: TodoModel,
  msg: TodoMsg,
) -> #(TodoModel, Effect(TodoMsg)) {
  case msg {
    // Toggle handler: user clicked checkbox
    todo_msg.ToggleTodo(id) -> {
      // Set loading state for visual feedback
      #(TodoModel(..model, loading: True), todo_effects.post_toggle(id))
    }

    // Toggle completed: server responded with updated state
    todo_msg.TodoToggled(Ok(result)) -> {
      let updated_model =
        TodoModel(
          ..model,
          todos: result.todos,
          active_count: result.active_count,
          loading: False,
          error: "",
        )
      #(updated_model, effect.none())
    }

    // Toggle failed: keep local state, show error
    todo_msg.TodoToggled(Error(err)) -> {
      let error_msg = format_error(err)
      #(TodoModel(..model, loading: False, error: error_msg), effect.none())
    }

    // Filter changed: update filter state
    todo_msg.SetFilter(filter) -> {
      #(TodoModel(..model, filter:), effect.none())
    }

    // Todos loaded from server
    todo_msg.GotTodos(Ok(todos)) -> {
      let active_count = todo_model.calculate_active_count(todos)
      #(TodoModel(..model, todos:, active_count:, error: ""), effect.none())
    }

    // Failed to load todos
    todo_msg.GotTodos(Error(err)) -> {
      let error_msg = format_error(err)
      #(TodoModel(..model, error: error_msg), effect.none())
    }

    // Delete handler
    todo_msg.DeleteTodo(id) -> {
      #(TodoModel(..model, loading: True), todo_effects.delete_todo(id))
    }

    // Delete completed successfully
    todo_msg.TodoDeleted(Ok(deleted_id)) -> {
      let updated_todos =
        list.filter(model.todos, fn(item) { item.id != deleted_id })
      let active_count = todo_model.calculate_active_count(updated_todos)
      #(TodoModel(..model, todos: updated_todos, active_count:, loading: False), effect.none())
    }

    // Delete failed
    todo_msg.TodoDeleted(Error(err)) -> {
      let error_msg = format_error(err)
      #(TodoModel(..model, loading: False, error: error_msg), effect.none())
    }

    // Clear error message
    todo_msg.ClearError -> {
      #(TodoModel(..model, error: ""), effect.none())
    }
  }
}

/// Format HTTP error to user-friendly message
fn format_error(err: TodoHttpError) -> String {
  case err {
    todo_msg.TodoNetworkError -> "Failed to reach server. Please check your connection."
    todo_msg.TodoDecodeError -> "Received invalid data from server."
    todo_msg.TodoServerError(code) -> "Server error (" <> int_to_string(code) <> "). Please try again."
  }
}

/// Convert int to string helper
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    i if i < 0 -> "-" <> int_to_string(-i)
    i -> int_to_string_positive(i)
  }
}

fn int_to_string_positive(n: Int) -> String {
  case n {
    0 -> ""
    i -> int_to_string_positive(i / 10) <> digit_to_string(i % 10)
  }
}

fn digit_to_string(d: Int) -> String {
  case d {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> ""
  }
}
