import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/otp/actor
import shared.{type Rating, Rating}
import web/auth
import web/rating_store.{type RatingStore}
import web/server.{type Request, type Response}

/// Handle POST /api/drinks/<drink_id>/ratings
pub fn submit(
  request: Request,
  drink_id: String,
  store: RatingStore,
) -> Response {
  case auth.get_user_id(request) {
    Error(_) ->
      server.json_response(
        401,
        json.object([#("error", json.string("Unauthorized"))])
          |> json.to_string,
      )
    Ok(user_id) -> {
      case decode_rating_input(request.body) {
        Error(msg) ->
          server.json_response(
            400,
            json.object([#("error", json.string(msg))]) |> json.to_string,
          )
        Ok(input) -> {
          case validate_scores(input) {
            Error(msg) ->
              server.json_response(
                400,
                json.object([#("error", json.string(msg))]) |> json.to_string,
              )
            Ok(_) -> {
              let id = generate_id()
              let rating =
                Rating(
                  id: id,
                  drink_id: drink_id,
                  user_id: user_id,
                  sweetness: input.sweetness,
                  texture: input.texture,
                  flavor: input.flavor,
                  overall: input.overall,
                  review: input.review,
                )
              let reply = process.new_subject()
              actor.send(store, rating_store.Submit(rating, reply))
              case process.receive(reply, 5000) {
                Ok(Ok(saved)) -> {
                  server.json_response(201, rating_to_json(saved))
                }
                _ ->
                  server.json_response(
                    500,
                    json.object([
                      #("error", json.string("Failed to save rating")),
                    ])
                      |> json.to_string,
                  )
              }
            }
          }
        }
      }
    }
  }
}

/// Handle GET /api/drinks/<drink_id>/ratings
pub fn get_for_drink(drink_id: String, store: RatingStore) -> Response {
  let reply = process.new_subject()
  actor.send(store, rating_store.GetByDrink(drink_id, reply))
  case process.receive(reply, 5000) {
    Ok(ratings) -> {
      let items = list.map(ratings, rating_to_json_value)
      server.json_response(
        200,
        json.object([
          #("drink_id", json.string(drink_id)),
          #("ratings", json.array(items, fn(x) { x })),
          #("count", json.int(list.length(ratings))),
        ])
          |> json.to_string,
      )
    }
    Error(_) ->
      server.json_response(
        500,
        json.object([#("error", json.string("Store timeout"))])
          |> json.to_string,
      )
  }
}

/// Handle GET /api/drinks/<drink_id>/ratings/aggregated
pub fn get_aggregated(drink_id: String, store: RatingStore) -> Response {
  let reply = process.new_subject()
  actor.send(store, rating_store.GetAggregated(drink_id, reply))
  case process.receive(reply, 5000) {
    Ok(Ok(agg)) -> {
      server.json_response(
        200,
        json.object([
          #("drink_id", json.string(agg.drink_id)),
          #("avg_sweetness", json.float(agg.avg_sweetness)),
          #("avg_texture", json.float(agg.avg_texture)),
          #("avg_flavor", json.float(agg.avg_flavor)),
          #("avg_overall", json.float(agg.avg_overall)),
          #("count", json.int(agg.count)),
        ])
          |> json.to_string,
      )
    }
    Ok(Error(_)) ->
      server.json_response(
        404,
        json.object([
          #("error", json.string("No ratings found for this drink")),
        ])
          |> json.to_string,
      )
    Error(_) ->
      server.json_response(
        500,
        json.object([#("error", json.string("Store timeout"))])
          |> json.to_string,
      )
  }
}

// -- Internal helpers --

type RatingInput {
  RatingInput(
    sweetness: Int,
    texture: Int,
    flavor: Int,
    overall: Int,
    review: String,
  )
}

fn decode_rating_input(body: String) -> Result(RatingInput, String) {
  let decoder = {
    use sweetness <- decode.field("sweetness", decode.int)
    use texture <- decode.field("texture", decode.int)
    use flavor <- decode.field("flavor", decode.int)
    use overall <- decode.field("overall", decode.int)
    use review <- decode.optional_field("review", "", decode.string)
    decode.success(RatingInput(
      sweetness: sweetness,
      texture: texture,
      flavor: flavor,
      overall: overall,
      review: review,
    ))
  }

  case json.parse(body, decoder) {
    Ok(input) -> Ok(input)
    Error(_) ->
      Error(
        "Invalid JSON: expected sweetness, texture, flavor, overall (int), optional review (string)",
      )
  }
}

fn validate_scores(input: RatingInput) -> Result(Nil, String) {
  case
    valid_score(input.sweetness)
    && valid_score(input.texture)
    && valid_score(input.flavor)
    && valid_score(input.overall)
  {
    True -> Ok(Nil)
    False -> Error("Scores must be between 1 and 5")
  }
}

fn valid_score(n: Int) -> Bool {
  n >= 1 && n <= 5
}

fn rating_to_json(rating: Rating) -> String {
  rating_to_json_value(rating) |> json.to_string
}

fn rating_to_json_value(rating: Rating) -> json.Json {
  json.object([
    #("id", json.string(rating.id)),
    #("drink_id", json.string(rating.drink_id)),
    #("user_id", json.string(rating.user_id)),
    #("sweetness", json.int(rating.sweetness)),
    #("texture", json.int(rating.texture)),
    #("flavor", json.int(rating.flavor)),
    #("overall", json.int(rating.overall)),
    #("review", json.string(rating.review)),
  ])
}

@external(erlang, "rating_ffi", "generate_id")
fn generate_id() -> String
