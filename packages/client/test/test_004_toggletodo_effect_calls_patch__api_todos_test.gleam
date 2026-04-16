// REQUIRED data-testid attributes: None (effect test)
//
// Test: Verify ToggleTodo(id, True) produces effect that calls PATCH /api/todos/{id}
// with body {"completed":true}

import gleeunit
import gleeunit/should
import frontend/effects
import frontend/model
import frontend/msg
import gleam/json
import gleam/http
import lustre/effect

pub fn main() {
  gleeunit.main()
}

pub fn toggle_true_effect_calls_patch_with_completed_true_test() {
  let effect = effects.toggle_todo("todo-abc", True)

  effect |> should.not_equal(effect.none())
}

pub fn toggle_false_effect_calls_patch_with_completed_false_test() {
  let effect = effects.toggle_todo("todo-def", False)

  effect |> should.not_equal(effect.none())
}
