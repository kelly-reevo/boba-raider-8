import gleeunit
import gleeunit/should
import frontend/model
import frontend/route

pub fn main() {
  gleeunit.main()
}

pub fn default_model_test() {
  let m = model.default()
  m.current_route
  |> should.equal(route.Home)
}

pub fn route_is_protected_test() {
  route.is_protected(route.Profile)
  |> should.equal(True)

  route.is_protected(route.StoreCreate)
  |> should.equal(True)

  route.is_protected(route.StoreEdit("123"))
  |> should.equal(True)

  route.is_protected(route.DrinkEdit("456"))
  |> should.equal(True)

  route.is_protected(route.Home)
  |> should.equal(False)

  route.is_protected(route.StoreList)
  |> should.equal(False)

  route.is_protected(route.StoreDetail("123"))
  |> should.equal(False)

  route.is_protected(route.Login)
  |> should.equal(False)
}

pub fn route_to_path_test() {
  route.to_path(route.Home)
  |> should.equal("/")

  route.to_path(route.StoreList)
  |> should.equal("/stores")

  route.to_path(route.StoreDetail("123"))
  |> should.equal("/stores/123")

  route.to_path(route.StoreCreate)
  |> should.equal("/stores/create")

  route.to_path(route.StoreEdit("123"))
  |> should.equal("/stores/123/edit")

  route.to_path(route.DrinkDetail("456"))
  |> should.equal("/drinks/456")

  route.to_path(route.DrinkEdit("456"))
  |> should.equal("/drinks/456/edit")

  route.to_path(route.Profile)
  |> should.equal("/profile")

  route.to_path(route.Login)
  |> should.equal("/login")

  route.to_path(route.Register)
  |> should.equal("/register")
}

pub fn route_from_path_test() {
  route.from_path("/")
  |> should.equal(route.Home)

  route.from_path("/stores")
  |> should.equal(route.StoreList)

  route.from_path("/stores/create")
  |> should.equal(route.StoreCreate)

  route.from_path("/login")
  |> should.equal(route.Login)

  route.from_path("/register")
  |> should.equal(route.Register)

  route.from_path("/profile")
  |> should.equal(route.Profile)
}

pub fn route_from_path_dynamic_test() {
  let store_detail = route.from_path("/stores/123")
  case store_detail {
    route.StoreDetail(id) -> id |> should.equal("123")
    _ -> should.fail()
  }

  let store_edit = route.from_path("/stores/123/edit")
  case store_edit {
    route.StoreEdit(id) -> id |> should.equal("123")
    _ -> should.fail()
  }

  let drink_detail = route.from_path("/drinks/456")
  case drink_detail {
    route.DrinkDetail(id) -> id |> should.equal("456")
    _ -> should.fail()
  }

  let drink_edit = route.from_path("/drinks/456/edit")
  case drink_edit {
    route.DrinkEdit(id) -> id |> should.equal("456")
    _ -> should.fail()
  }
}
