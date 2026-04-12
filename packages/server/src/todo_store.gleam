import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/string
import shared.{type Todo, type UpdateTodoInput, Todo}

// Store reference type
pub opaque type Store {
  Store(subject: Subject(Message))
}

// Store state: a dictionary of todos keyed by id
pub type State {
  State(todos: Dict(String, Todo), next_id: Int)
}

// Message type for the actor
pub type Message {
  // Create a new todo
  CreateTodo(
    title: String,
    description: String,
    reply_to: Subject(Result(Todo, String)),
  )
  // Get a single todo by ID
  GetTodo(id: String, reply_to: Subject(Option(Todo)))
  // Get all todos
  GetAllTodos(reply_to: Subject(List(Todo)))
  // Update a todo
  UpdateTodo(
    id: String,
    input: UpdateTodoInput,
    reply_to: Subject(Result(Todo, String)),
  )
  // Delete a todo
  DeleteTodo(id: String, reply_to: Subject(Result(Nil, String)))
}

// Start the todo store actor
pub fn start() -> Result(Store, String) {
  let initial_state = State(todos: dict.new(), next_id: 1)

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(Store(started.data))
    Error(_) -> Error("Failed to start todo store actor")
  }
}

// Actor message handler
fn handle_message(
  state: State,
  msg: Message,
) -> actor.Next(State, Message) {
  case msg {
    CreateTodo(title, description, reply_to) -> {
      let trimmed_title = string.trim(title)

      case string.is_empty(trimmed_title) {
        True -> {
          process.send(reply_to, Error("Title is required"))
          actor.continue(state)
        }
        False -> {
          let id = generate_id(state.next_id)
          let now = current_timestamp()
          let new_todo =
            Todo(
              id: id,
              title: trimmed_title,
              description: description,
              completed: False,
              created_at: now,
              updated_at: now,
            )

          let new_todos = dict.insert(state.todos, id, new_todo)
          let new_state = State(todos: new_todos, next_id: state.next_id + 1)

          process.send(reply_to, Ok(new_todo))
          actor.continue(new_state)
        }
      }
    }

    GetTodo(id, reply_to) -> {
      let result = dict.get(state.todos, id)
      let option_result = option.from_result(result)
      process.send(reply_to, option_result)
      actor.continue(state)
    }

    GetAllTodos(reply_to) -> {
      let todos = dict.values(state.todos)
      process.send(reply_to, todos)
      actor.continue(state)
    }

    UpdateTodo(id, input, reply_to) -> {
      case dict.get(state.todos, id) {
        Error(_) -> {
          process.send(reply_to, Error("Todo not found"))
          actor.continue(state)
        }
        Ok(existing) -> {
          let now = current_timestamp()
          let updated =
            Todo(
              id: existing.id,
              title: option.unwrap(input.title, existing.title),
              description: option.unwrap(
                input.description,
                existing.description,
              ),
              completed: option.unwrap(input.completed, existing.completed),
              created_at: existing.created_at,
              updated_at: now,
            )

          let new_todos = dict.insert(state.todos, id, updated)
          let new_state = State(..state, todos: new_todos)

          process.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
      }
    }

    DeleteTodo(id, reply_to) -> {
      case dict.has_key(state.todos, id) {
        False -> {
          process.send(reply_to, Error("Todo not found"))
          actor.continue(state)
        }
        True -> {
          let new_todos = dict.delete(state.todos, id)
          let new_state = State(..state, todos: new_todos)

          process.send(reply_to, Ok(Nil))
          actor.continue(new_state)
        }
      }
    }
  }
}

// Generate a unique ID for todos
fn generate_id(counter: Int) -> String {
  let timestamp = current_timestamp()
  int_to_string(timestamp) <> "-" <> int_to_string(counter)
}

// Get current timestamp (in Erlang, system_time in milliseconds)
@external(erlang, "erlang", "system_time")
fn system_time(unit: a) -> Int

fn current_timestamp() -> Int {
  system_time(1000)
}

// Convert int to string
fn int_to_string(n: Int) -> String {
  do_int_to_string(n)
}

fn do_int_to_string(n: Int) -> String {
  case n {
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
    _ -> {
      let quotient = n / 10
      let remainder = n % 10
      case quotient {
        0 -> do_int_to_string(remainder)
        _ -> do_int_to_string(quotient) <> do_int_to_string(remainder)
      }
    }
  }
}

// Public API: Create a new todo
pub fn create_todo(
  store: Store,
  title: String,
  description: String,
) -> Result(Todo, String) {
  process.call(store.subject, 5000, CreateTodo(title, description, _))
}

// Public API: Get a single todo by ID
pub fn get_todo(store: Store, id: String) -> Option(Todo) {
  process.call(store.subject, 5000, GetTodo(id, _))
}

// Public API: Get all todos
pub fn get_all_todos(store: Store) -> List(Todo) {
  process.call(store.subject, 5000, GetAllTodos(_))
}

// Public API: Update a todo
pub fn update_todo(
  store: Store,
  id: String,
  input: UpdateTodoInput,
) -> Result(Todo, String) {
  process.call(store.subject, 5000, UpdateTodo(id, input, _))
}

// Public API: Delete a todo
pub fn delete_todo(store: Store, id: String) -> Result(Nil, String) {
  process.call(store.subject, 5000, DeleteTodo(id, _))
}
