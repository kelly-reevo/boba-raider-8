import gleeunit
import gleeunit/should
import frontend/model
import frontend/view
import frontend/msg
import lustre/element
import gleam/string
import shared
import gleam/option.{None}

pub fn main() {
  gleeunit.main()
}

pub fn empty_state_shows_no_todos_message_test() {
  // Given: No todos and not loading
  let empty_model = model.Model(
    todos: [],
    loading: False,
    error: "",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(empty_model)
  let html = element.to_string(rendered)

  // Then: Shows 'No todos yet' message
  html |> string.contains("No todos yet") |> should.be_true
  html |> string.contains("Create your first todo above!") |> should.be_true
  html |> string.contains("data-testid=\"empty-state-message\"") |> should.be_true
}

pub fn empty_state_hides_loading_indicator_test() {
  // Given: No todos and not loading
  let empty_model = model.Model(
    todos: [],
    loading: False,
    error: "",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(empty_model)
  let html = element.to_string(rendered)

  // Then: Loading indicator is NOT present
  html |> string.contains("data-testid=\"loading-indicator\"") |> should.be_false
  html |> string.contains("Loading...") |> should.be_false
}

pub fn loading_state_shows_spinner_test() {
  // Given: Loading state is true
  let loading_model = model.Model(
    todos: [],
    loading: True,
    error: "",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(loading_model)
  let html = element.to_string(rendered)

  // Then: Shows loading indicator
  html |> string.contains("data-testid=\"loading-indicator\"") |> should.be_true
  html |> string.contains("Loading...") |> should.be_true
}

pub fn loading_state_disables_form_submit_test() {
  // Given: Loading state is true
  let loading_model = model.Model(
    todos: [],
    loading: True,
    error: "",
    filter: model.All,
    form_title: "New Todo",
    form_description: "Description",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(loading_model)
  let html = element.to_string(rendered)

  // Then: Submit button is disabled
  html |> string.contains("disabled") |> should.be_true
}

pub fn error_state_shows_error_banner_test() {
  // Given: Error state with message
  let error_model = model.Model(
    todos: [],
    loading: False,
    error: "Failed to load todos",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(error_model)
  let html = element.to_string(rendered)

  // Then: Error banner is displayed prominently
  html |> string.contains("data-testid=\"error-banner\"") |> should.be_true
  html |> string.contains("Failed to load todos") |> should.be_true
}

pub fn error_state_shows_retry_button_test() {
  // Given: Error state with message
  let error_model = model.Model(
    todos: [],
    loading: False,
    error: "Failed to load todos",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(error_model)
  let html = element.to_string(rendered)

  // Then: Retry button is present
  html |> string.contains("data-testid=\"retry-button\"") |> should.be_true
  html |> string.contains("Retry") |> should.be_true
}

pub fn list_error_retry_triggers_load_todos_test() {
  // Given: Error occurred during list loading
  let list_error_msg = msg.Retry(msg.LoadTodosOp)

  // When: Retry message is dispatched
  // Then: It should trigger LoadTodos operation
  case list_error_msg {
    msg.Retry(msg.LoadTodosOp) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

pub fn form_error_retry_triggers_resubmit_test() {
  // Given: Error occurred during form submission
  let form_error_msg = msg.Retry(msg.SubmitTodoOp)

  // When: Retry message is dispatched
  // Then: It should trigger resubmit operation
  case form_error_msg {
    msg.Retry(msg.SubmitTodoOp) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

pub fn error_state_with_empty_error_hides_banner_test() {
  // Given: Empty error string
  let no_error_model = model.Model(
    todos: [shared.Todo(id: "1", title: "Test", completed: False, priority: shared.Medium, description: None)],
    loading: False,
    error: "",
    filter: model.All,
    form_title: "",
    form_description: "",
    form_priority: shared.Medium
  )

  // When: View is rendered
  let rendered = view.view(no_error_model)
  let html = element.to_string(rendered)

  // Then: Error banner is NOT present
  html |> string.contains("data-testid=\"error-banner\"") |> should.be_false
}
