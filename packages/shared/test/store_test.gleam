import gleam/json
import gleeunit/should
import shared/store

pub fn new_store_test() {
  let addr = store.Address(
    street: "123 Boba St",
    city: "San Francisco",
    state: "CA",
    zip: "94102",
  )
  let s = store.new("s1", "Happy Boba", addr, store.default_hours(), "Best boba in SF")

  store.store_id_to_string(s.id) |> should.equal("s1")
  s.name |> should.equal("Happy Boba")
  s.address.city |> should.equal("San Francisco")
  s.description |> should.equal("Best boba in SF")
}

pub fn json_roundtrip_test() {
  let addr = store.Address(
    street: "456 Tea Ave",
    city: "Portland",
    state: "OR",
    zip: "97201",
  )
  let s = store.new("s2", "Bubble Lab", addr, store.default_hours(), "Experimental flavors")

  let json_str =
    s
    |> store.store_to_json
    |> json.to_string

  let result = json.parse(json_str, store.store_decoder())
  should.be_ok(result)

  let assert Ok(decoded) = result
  decoded.name |> should.equal("Bubble Lab")
  store.store_id_to_string(decoded.id) |> should.equal("s2")
  decoded.address.city |> should.equal("Portland")
  decoded.description |> should.equal("Experimental flavors")
}

pub fn default_hours_test() {
  let hours = store.default_hours()
  hours.monday |> should.equal(store.DayHours("10:00", "21:00"))
  hours.sunday |> should.equal(store.Closed)
}
