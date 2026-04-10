import gleeunit
import gleeunit/should
import frontend/model.{CounterPage}

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  // Check that default page is CounterPage with count = 0
  case m.page {
    CounterPage(count, _) -> count |> should.equal(0)
    _ -> panic as "Expected CounterPage as default page"
  }
}
