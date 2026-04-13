/// Todo domain types

pub type Filter {
  All
  Active
  Completed
}

pub type Todo {
  Todo(id: String, title: String, completed: Bool)
}

pub fn filter_to_string(filter: Filter) -> String {
  case filter {
    All -> "all"
    Active -> "active"
    Completed -> "completed"
  }
}
