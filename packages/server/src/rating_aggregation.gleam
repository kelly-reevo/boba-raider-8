import gleam/float
import gleam/int
import gleam/list
import shared.{
  type DrinkId, type Rating, type RatingAggregation, type StoreId,
  RatingAggregation, empty_aggregation,
}

/// Aggregate a list of ratings into averages per dimension and an overall score
pub fn aggregate(ratings: List(Rating)) -> RatingAggregation {
  case ratings {
    [] -> empty_aggregation
    _ -> {
      let count = list.length(ratings)
      let count_f = int.to_float(count)
      let sum_sweetness = sum_by(ratings, fn(r) { r.sweetness })
      let sum_flavor = sum_by(ratings, fn(r) { r.flavor })
      let sum_value = sum_by(ratings, fn(r) { r.value })
      let avg_sweetness = sum_sweetness /. count_f
      let avg_flavor = sum_flavor /. count_f
      let avg_value = sum_value /. count_f
      let overall = { avg_sweetness +. avg_flavor +. avg_value } /. 3.0
      RatingAggregation(
        count: count,
        avg_sweetness: round2(avg_sweetness),
        avg_flavor: round2(avg_flavor),
        avg_value: round2(avg_value),
        overall: round2(overall),
      )
    }
  }
}

/// Aggregate ratings filtered to a specific drink
pub fn aggregate_for_drink(
  ratings: List(Rating),
  drink_id: DrinkId,
) -> RatingAggregation {
  ratings
  |> list.filter(fn(r) { r.drink_id == drink_id })
  |> aggregate
}

/// Aggregate ratings filtered to a specific store
pub fn aggregate_for_store(
  ratings: List(Rating),
  store_id: StoreId,
) -> RatingAggregation {
  ratings
  |> list.filter(fn(r) { r.store_id == store_id })
  |> aggregate
}

fn sum_by(ratings: List(Rating), f: fn(Rating) -> Float) -> Float {
  list.fold(ratings, 0.0, fn(acc, r) { acc +. f(r) })
}

fn round2(val: Float) -> Float {
  let multiplied = val *. 100.0
  let rounded = float.round(multiplied)
  int.to_float(rounded) /. 100.0
}
