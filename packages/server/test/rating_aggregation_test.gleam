import gleeunit/should
import rating_aggregation
import shared.{Rating, empty_aggregation}

pub fn aggregate_empty_list_test() {
  rating_aggregation.aggregate([])
  |> should.equal(empty_aggregation)
}

pub fn aggregate_single_rating_test() {
  let rating =
    Rating(
      id: "r1",
      drink_id: "d1",
      user_id: "u1",
      sweetness: 4,
      texture: 3,
      flavor: 3,
      overall: 5,
      review: "",
    )
  let result = rating_aggregation.aggregate([rating])
  result.count |> should.equal(1)
  result.avg_sweetness |> should.equal(4.0)
  result.avg_flavor |> should.equal(3.0)
  result.avg_value |> should.equal(5.0)
  result.overall |> should.equal(4.0)
}

pub fn aggregate_multiple_ratings_test() {
  let r1 =
    Rating(
      id: "r1",
      drink_id: "d1",
      user_id: "u1",
      sweetness: 4,
      texture: 3,
      flavor: 3,
      overall: 5,
      review: "",
    )
  let r2 =
    Rating(
      id: "r2",
      drink_id: "d1",
      user_id: "u2",
      sweetness: 2,
      texture: 4,
      flavor: 5,
      overall: 3,
      review: "",
    )
  let result = rating_aggregation.aggregate([r1, r2])
  result.count |> should.equal(2)
  result.avg_sweetness |> should.equal(3.0)
  result.avg_flavor |> should.equal(4.0)
  result.avg_value |> should.equal(4.0)
  result.overall |> should.equal(3.67)
}

pub fn aggregate_for_drink_filters_correctly_test() {
  let r1 =
    Rating(
      id: "r1",
      drink_id: "d1",
      user_id: "u1",
      sweetness: 4,
      texture: 4,
      flavor: 4,
      overall: 4,
      review: "",
    )
  let r2 =
    Rating(
      id: "r2",
      drink_id: "d2",
      user_id: "u2",
      sweetness: 1,
      texture: 1,
      flavor: 1,
      overall: 1,
      review: "",
    )
  let result = rating_aggregation.aggregate_for_drink([r1, r2], "d1")
  result.count |> should.equal(1)
  result.avg_sweetness |> should.equal(4.0)
}

pub fn aggregate_for_nonexistent_drink_returns_empty_test() {
  let r1 =
    Rating(
      id: "r1",
      drink_id: "d1",
      user_id: "u1",
      sweetness: 4,
      texture: 4,
      flavor: 4,
      overall: 4,
      review: "",
    )
  let result =
    rating_aggregation.aggregate_for_drink([r1], "nonexistent")
  result |> should.equal(empty_aggregation)
}
