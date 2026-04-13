import gleeunit
import gleeunit/should
import frontend/store_list/model as store_model

pub fn main() {
  gleeunit.main()
}

pub fn default_store_model_test() {
  let m = store_model.default()
  m.search_term
  |> should.equal("")
}

pub fn default_pagination_test() {
  let m = store_model.default()
  m.pagination.limit
  |> should.equal(20)
}

pub fn pagination_has_next_page_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 0, total: 45)
  store_model.has_next_page(pagination)
  |> should.equal(True)
}

pub fn pagination_no_next_on_last_page_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 40, total: 45)
  store_model.has_next_page(pagination)
  |> should.equal(False)
}

pub fn pagination_has_prev_page_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 20, total: 45)
  store_model.has_prev_page(pagination)
  |> should.equal(True)
}

pub fn pagination_no_prev_on_first_page_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 0, total: 45)
  store_model.has_prev_page(pagination)
  |> should.equal(False)
}

pub fn total_pages_calculation_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 0, total: 45)
  store_model.total_pages(pagination)
  |> should.equal(3)
}

pub fn current_page_calculation_test() {
  let pagination = store_model.Pagination(limit: 20, offset: 40, total: 45)
  store_model.current_page(pagination)
  |> should.equal(3)
}
