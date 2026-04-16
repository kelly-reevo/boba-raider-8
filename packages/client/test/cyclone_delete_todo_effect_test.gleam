// === REQUIRED data-testid ATTRIBUTES ===
// - delete-btn-{id}: Delete button on each todo item
// - todo-item-{id}: Container for each todo item in the list
// - error-message: Error display element

import gleeunit/should
import frontend/effects
import gleam/http
import gleam/option

// Test that delete_todo effect constructs correct HTTP request
pub fn delete_todo_effect_sends_delete_request_test() {
  let todo_id = "todo-123"
  let effect = effects.delete_todo(todo_id)
  
  // Verify the effect makes DELETE request to correct endpoint
  effects.inspect_effect(effect) |> should.equal(
    effects.EffectDetails(
      method: http.Delete,
      url: "/api/todos/todo-123",
      headers: [],
      body: option.None
    )
  )
}

// Test that delete effect handles 204 No Content success
pub fn delete_effect_handles_204_success_test() {
  let mock_response = effects.MockResponse(
    status: 204,
    body: ""
  )
  
  let result = effects.run_delete_todo_effect("todo-123", mock_response)
  
  // Should return Ok with todo id on 204
  result |> should.equal(Ok("todo-123"))
}

// Test that delete effect handles 404 not found error
pub fn delete_effect_handles_404_error_test() {
  let mock_response = effects.MockResponse(
    status: 404,
    body: "{\"error\":\"Todo not found\"}"
  )
  
  let result = effects.run_delete_todo_effect("todo-123", mock_response)
  
  // Should return error
  result |> should.equal(Error("Todo not found"))
}

// Test that delete effect handles network failure
pub fn delete_effect_handles_network_failure_test() {
  let result = effects.simulate_delete_todo_error("todo-123", "NetworkError")
  
  result |> should.equal(Error("Network error"))
}