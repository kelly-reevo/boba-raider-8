import gleeunit
import gleeunit/should
import config
import gleam/list
import gleam/option.{None, Some}
import shared
import web/store

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

// ============== Store Domain Tests ==============

pub fn tea_type_from_string_test() {
  store.tea_type_from_string("black")
  |> should.equal(Ok(store.Black))

  store.tea_type_from_string("BLACK")
  |> should.equal(Ok(store.Black))

  store.tea_type_from_string("green")
  |> should.equal(Ok(store.Green))

  store.tea_type_from_string("matcha")
  |> should.equal(Ok(store.Matcha))
}

pub fn tea_type_from_string_invalid_test() {
  let result = store.tea_type_from_string("invalid")
  case result {
    Error(shared.InvalidInput(_)) -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn get_store_existing_test() {
  let result = store.get_store("store-1")
  case result {
    Ok(store) -> {
      store.id |> should.equal("store-1")
      store.name |> should.equal("Boba Paradise")
    }
    Error(_) -> should.fail()
  }
}

pub fn get_store_not_found_test() {
  let result = store.get_store("non-existent")
  case result {
    Error(shared.NotFound(_)) -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn list_drinks_success_test() {
  let result = store.list_drinks("store-1", None, store.RatingDesc, 1, 10)
  case result {
    Ok(#(drinks, meta)) -> {
      // store-1 has 3 drinks
      meta.total |> should.equal(3)
      meta.page |> should.equal(1)
      list.length(drinks) |> should.equal(3)
    }
    Error(_) -> should.fail()
  }
}

pub fn list_drinks_store_not_found_test() {
  let result = store.list_drinks("non-existent", None, store.RatingDesc, 1, 10)
  case result {
    Error(shared.NotFound(_)) -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn list_drinks_filter_by_tea_type_test() {
  let result = store.list_drinks("store-1", Some(store.Black), store.RatingDesc, 1, 10)
  case result {
    Ok(#(drinks, meta)) -> {
      meta.total |> should.equal(1)
      case drinks {
        [drink] -> drink.name |> should.equal("Classic Milk Tea")
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn list_drinks_sort_by_name_test() {
  let result = store.list_drinks("store-1", None, store.Name, 1, 10)
  case result {
    Ok(#(drinks, _)) -> {
      case drinks {
        [first, ..] -> first.name |> should.equal("Classic Milk Tea")
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn list_drinks_pagination_test() {
  let result = store.list_drinks("store-1", None, store.Name, 1, 2)
  case result {
    Ok(#(drinks, meta)) -> {
      meta.total |> should.equal(3)
      meta.total_pages |> should.equal(2)
      list.length(drinks) |> should.equal(2)
    }
    Error(_) -> should.fail()
  }
}

pub fn list_drinks_pagination_second_page_test() {
  let result = store.list_drinks("store-1", None, store.Name, 2, 2)
  case result {
    Ok(#(drinks, meta)) -> {
      meta.page |> should.equal(2)
      list.length(drinks) |> should.equal(1)
    }
    Error(_) -> should.fail()
  }
}
