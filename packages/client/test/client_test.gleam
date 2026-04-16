import gleeunit
import gleeunit/should
import frontend/filter
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.todos |> should.equal([])
  m.filter |> should.equal(filter.All)
  m.input_text |> should.equal("")
}

pub fn todo_item_creation_test() {
  let item = filter.TodoItem(
    id: "1",
    title: "Test task",
    description: "Test description",
    priority: "high",
    completed: False,
    created_at: "2024-01-01",
    updated_at: "2024-01-01",
  )
  item.id |> should.equal("1")
  item.title |> should.equal("Test task")
  item.completed |> should.equal(False)
}
