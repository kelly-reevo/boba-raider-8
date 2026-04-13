/// Application messages

import frontend/todo_types.{type Filter, type Todo}

pub type Msg {
  // Counter messages (existing)
  Increment
  Decrement
  Reset

  // Filter messages
  FilterChanged(Filter)
  TodosLoaded(Result(List(Todo), String))
}
