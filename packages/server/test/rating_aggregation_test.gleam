import gleeunit/should
import rating_aggregation
import shared.{DrinkId, Rating, RatingId, StoreId, empty_aggregation}

pub fn aggregate_empty_list_test() {
  rating_aggregation.aggregate([])
  |> should.equal(empty_aggregation)
}

pub fn aggregate_single_rating_test() {
  let rating =
    Rating(
      id: RatingId("r1"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 4.0,
      flavor: 3.0,
      value: 5.0,
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
      id: RatingId("r1"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 4.0,
      flavor: 3.0,
      value: 5.0,
    )
  let r2 =
    Rating(
      id: RatingId("r2"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 2.0,
      flavor: 5.0,
      value: 3.0,
    )
  let result = rating_aggregation.aggregate([r1, r2])
  result.count |> should.equal(2)
  result.avg_sweetness |> should.equal(3.0)
  result.avg_flavor |> should.equal(4.0)
  result.avg_value |> should.equal(4.0)
  result.overall |> should.equal(3.67)
}

pub fn aggregate_for_drink_filters_correctly_test() {
  let target = DrinkId("d1")
  let r1 =
    Rating(
      id: RatingId("r1"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 4.0,
      flavor: 4.0,
      value: 4.0,
    )
  let r2 =
    Rating(
      id: RatingId("r2"),
      drink_id: DrinkId("d2"),
      store_id: StoreId("s1"),
      sweetness: 1.0,
      flavor: 1.0,
      value: 1.0,
    )
  let result = rating_aggregation.aggregate_for_drink([r1, r2], target)
  result.count |> should.equal(1)
  result.avg_sweetness |> should.equal(4.0)
}

pub fn aggregate_for_store_filters_correctly_test() {
  let target = StoreId("s2")
  let r1 =
    Rating(
      id: RatingId("r1"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 1.0,
      flavor: 1.0,
      value: 1.0,
    )
  let r2 =
    Rating(
      id: RatingId("r2"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s2"),
      sweetness: 5.0,
      flavor: 5.0,
      value: 5.0,
    )
  let result = rating_aggregation.aggregate_for_store([r1, r2], target)
  result.count |> should.equal(1)
  result.overall |> should.equal(5.0)
}

pub fn aggregate_for_nonexistent_drink_returns_empty_test() {
  let r1 =
    Rating(
      id: RatingId("r1"),
      drink_id: DrinkId("d1"),
      store_id: StoreId("s1"),
      sweetness: 4.0,
      flavor: 4.0,
      value: 4.0,
    )
  let result =
    rating_aggregation.aggregate_for_drink([r1], DrinkId("nonexistent"))
  result |> should.equal(empty_aggregation)
}
