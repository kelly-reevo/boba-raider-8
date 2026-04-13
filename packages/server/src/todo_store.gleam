import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject, type Pid}
import gleam/otp/actor
import gleam/list

/// Todo record representing a todo item
pub type Todo {
  Todo(
    id: String,
    title: String,
    description: String,
    priority: String,
    completed: Bool,
    created_at: Int,
  )
}

/// Input data for creating a todo
pub type TodoData {
  TodoData(
    title: String,
    description: String,
    priority: String,
    completed: Bool,
  )
}

/// Dynamic type for update values
pub type Dynamic {
  BoolValue(Bool)
  StringValue(String)
}

/// Messages that can be sent to the TodoStore actor
pub type TodoStoreMsg {
  Create(TodoData, Subject(Result(Todo, String)))
  Get(String, Subject(Result(Todo, String)))
  GetAll(String, Subject(Result(List(Todo), String)))
  Update(String, List(#(String, Dynamic)), Subject(Result(Todo, String)))
  Delete(String, Subject(Result(Nil, String)))
}

/// Actor state - in-memory map of todos
pub type State {
  State(todos: Dict(String, Todo), next_id: Int)
}

/// Start the TodoStore actor and register it with the given name
pub fn start_and_register(name: String) -> Result(Pid, String) {
  let initial_state = State(todos: dict.new(), next_id: 1)

  case actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start() {
    Ok(started) -> {
      let subject = started.data
      case process.subject_owner(subject) {
        Ok(pid) -> {
          // Register the process with the given name
          let name_reg = process.new_name(name)
          let _ = process.register(pid, name_reg)
          Ok(pid)
        }
        Error(_) -> Error("Failed to get subject owner")
      }
    }
    Error(_) -> Error("Failed to start todo store actor")
  }
}

/// Handle incoming messages to the actor
fn handle_message(state: State, msg: TodoStoreMsg) -> actor.Next(State, TodoStoreMsg) {
  case msg {
    Create(todo_data, reply_to) -> {
      let #(new_state, result) = do_create(state, todo_data)
      process.send(reply_to, result)
      actor.continue(new_state)
    }
    Get(id, reply_to) -> {
      let result = do_get(state, id)
      process.send(reply_to, result)
      actor.continue(state)
    }
    GetAll(filter, reply_to) -> {
      let result = do_get_all(state, filter)
      process.send(reply_to, result)
      actor.continue(state)
    }
    Update(id, changes, reply_to) -> {
      let #(new_state, result) = do_update(state, id, changes)
      process.send(reply_to, result)
      actor.continue(new_state)
    }
    Delete(id, reply_to) -> {
      let #(new_state, result) = do_delete(state, id)
      process.send(reply_to, result)
      actor.continue(new_state)
    }
  }
}

/// Create a new todo
fn do_create(state: State, data: TodoData) -> #(State, Result(Todo, String)) {
  // Validate priority
  let valid_priority = case data.priority {
    "high" | "medium" | "low" -> True
    _ -> False
  }

  case valid_priority {
    False -> #(state, Error("invalid_priority"))
    True -> {
      let id = generate_id(state.next_id)
      let new_todo = Todo(
        id: id,
        title: data.title,
        description: data.description,
        priority: data.priority,
        completed: data.completed,
        created_at: state.next_id,
      )
      let new_todos = dict.insert(state.todos, id, new_todo)
      let new_state = State(todos: new_todos, next_id: state.next_id + 1)
      #(new_state, Ok(new_todo))
    }
  }
}

/// Get a todo by id
fn do_get(state: State, id: String) -> Result(Todo, String) {
  case dict.get(state.todos, id) {
    Ok(t) -> Ok(t)
    Error(_) -> Error("not_found")
  }
}

/// Get all todos with optional filtering
fn do_get_all(state: State, filter: String) -> Result(List(Todo), String) {
  let all = dict.values(state.todos)

  let filtered = case filter {
    "all" -> all
    "completed" -> list.filter(all, fn(t) { t.completed })
    "active" | "pending" | "not_completed" -> list.filter(all, fn(t) { !t.completed })
    _ -> all
  }

  Ok(filtered)
}

/// Update a todo
fn do_update(
  state: State,
  id: String,
  changes: List(#(String, Dynamic)),
) -> #(State, Result(Todo, String)) {
  case dict.get(state.todos, id) {
    Error(_) -> #(state, Error("not_found"))
    Ok(existing) -> {
      let updated = apply_changes(existing, changes)
      let new_todos = dict.insert(state.todos, id, updated)
      let new_state = State(..state, todos: new_todos)
      #(new_state, Ok(updated))
    }
  }
}

/// Apply changes to a todo
fn apply_changes(t: Todo, changes: List(#(String, Dynamic))) -> Todo {
  case changes {
    [] -> t
    [#(field, value), ..rest] -> {
      let updated = case field {
        "title" -> case value {
          StringValue(s) -> Todo(..t, title: s)
          _ -> t
        }
        "description" -> case value {
          StringValue(s) -> Todo(..t, description: s)
          _ -> t
        }
        "priority" -> case value {
          StringValue(s) -> Todo(..t, priority: s)
          _ -> t
        }
        "completed" -> case value {
          BoolValue(b) -> Todo(..t, completed: b)
          _ -> t
        }
        _ -> t
      }
      apply_changes(updated, rest)
    }
  }
}

/// Delete a todo
fn do_delete(state: State, id: String) -> #(State, Result(Nil, String)) {
  case dict.get(state.todos, id) {
    Error(_) -> #(state, Error("not_found"))
    Ok(_) -> {
      let new_todos = dict.delete(state.todos, id)
      let new_state = State(..state, todos: new_todos)
      #(new_state, Ok(Nil))
    }
  }
}

/// Generate a unique ID string
fn generate_id(n: Int) -> String {
  "todo-" <> int_to_string(n)
}

/// Convert int to string
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> int_to_string_impl(n, "")
  }
}

fn int_to_string_impl(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> int_to_string_impl(n / 10, char_to_string(n % 10) <> acc)
  }
}

fn char_to_string(i: Int) -> String {
  case i {
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

/// Convenience function to create a todo from a tuple (for test compatibility)
pub fn tuple_to_todo_data(tuple: #(String, String, String, Bool)) -> TodoData {
  TodoData(
    title: tuple.0,
    description: tuple.1,
    priority: tuple.2,
    completed: tuple.3,
  )
}

/// Helper to wrap a value in StringValue
pub fn string_value(s: String) -> Dynamic {
  StringValue(s)
}

/// Helper to wrap a value in BoolValue
pub fn bool_value(b: Bool) -> Dynamic {
  BoolValue(b)
}
