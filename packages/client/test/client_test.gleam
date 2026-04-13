import gleeunit
import gleeunit/should
import frontend/model

pub fn main() {
  gleeunit.main()
}

pub fn init_model_test() {
  let m = model.init()
  m.is_loading
  |> should.equal(True)

  m.loading_message
  |> should.equal("Loading todos...")

  m.submit_button_text
  |> should.equal("Add Todo")
}
