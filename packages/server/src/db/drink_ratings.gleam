import db
import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import sqlight

/// Rating score from 1-5
pub type RatingScore {
  RatingScore(Int)
}

/// Create a rating score with validation
pub fn rating_score(value: Int) -> Result(RatingScore, String) {
  case value >= 1 && value <= 5 {
    True -> Ok(RatingScore(value))
    False -> Error("Rating must be between 1 and 5")
  }
}

/// Get integer value from rating
pub fn score_value(score: RatingScore) -> Int {
  let RatingScore(v) = score
  v
}

/// Drink rating record
pub type DrinkRating {
  DrinkRating(
    id: String,
    drink_id: String,
    user_id: String,
    overall_score: RatingScore,
    sweetness: RatingScore,
    boba_texture: RatingScore,
    tea_strength: RatingScore,
    review_text: Option(String),
    created_at: String,
    updated_at: String,
  )
}

/// Convert sqlight error to string
fn sqlight_error_to_string(err: sqlight.Error) -> String {
  let sqlight.SqlightError(_code, message, _offset) = err
  "SQL error [" <> message <> "]"
}

/// Helper to decode a field from a tuple at given index
fn tuple_field(index: Int, inner: Decoder(a)) -> Decoder(a) {
  decode.at([index], inner)
}

/// Decoder for a DrinkRating from query result (tuple of 10 elements)
fn drink_rating_decoder() -> Decoder(DrinkRating) {
  // Decode id at index 0
  tuple_field(0, decode.string)
  |> decode.map(fn(id) {
    // We need to decode all fields, so use decode.map repeatedly
    id
  })
  |> decode.then(fn(id) {
    decode.map(tuple_field(1, decode.string), fn(drink_id) { #(id, drink_id) })
  })
  |> decode.then(fn(pair1) {
    decode.map(tuple_field(2, decode.string), fn(user_id) {
      #(pair1.0, pair1.1, user_id)
    })
  })
  |> decode.then(fn(triple) {
    decode.map(tuple_field(3, decode.int), fn(overall) {
      #(triple.0, triple.1, triple.2, overall)
    })
  })
  |> decode.then(fn(quad) {
    decode.map(tuple_field(4, decode.int), fn(sweetness) {
      #(quad.0, quad.1, quad.2, quad.3, sweetness)
    })
  })
  |> decode.then(fn(pent) {
    decode.map(tuple_field(5, decode.int), fn(boba) {
      #(pent.0, pent.1, pent.2, pent.3, pent.4, boba)
    })
  })
  |> decode.then(fn(hex) {
    decode.map(tuple_field(6, decode.int), fn(tea) {
      #(hex.0, hex.1, hex.2, hex.3, hex.4, hex.5, tea)
    })
  })
  |> decode.then(fn(sept) {
    decode.map(tuple_field(7, decode.string), fn(review) {
      #(sept.0, sept.1, sept.2, sept.3, sept.4, sept.5, sept.6, review)
    })
  })
  |> decode.then(fn(oct) {
    decode.map(tuple_field(8, decode.string), fn(created) {
      #(oct.0, oct.1, oct.2, oct.3, oct.4, oct.5, oct.6, oct.7, created)
    })
  })
  |> decode.then(fn(non) {
    decode.map(tuple_field(9, decode.string), fn(updated) {
      DrinkRating(
        id: non.0,
        drink_id: non.1,
        user_id: non.2,
        overall_score: RatingScore(non.3),
        sweetness: RatingScore(non.4),
        boba_texture: RatingScore(non.5),
        tea_strength: RatingScore(non.6),
        review_text: case non.7 {
          "" -> None
          text -> Some(text)
        },
        created_at: non.8,
        updated_at: updated,
      )
    })
  })
}

/// Create a new rating
pub fn create(
  db: db.Connection,
  id: String,
  drink_id: String,
  user_id: String,
  overall_score: Int,
  sweetness: Int,
  boba_texture: Int,
  tea_strength: Int,
  review_text: Option(String),
) -> Result(DrinkRating, db.DbError) {
  let sql = "INSERT INTO drink_ratings (
    id, drink_id, user_id, overall_score, sweetness, boba_texture, tea_strength, review_text
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"

  let review = option.unwrap(review_text, "")
  let row_decoder: Decoder(Int) = decode.int

  case
    sqlight.query(
      sql,
      db.conn,
      [
        sqlight.text(id),
        sqlight.text(drink_id),
        sqlight.text(user_id),
        sqlight.int(overall_score),
        sqlight.int(sweetness),
        sqlight.int(boba_texture),
        sqlight.int(tea_strength),
        sqlight.text(review),
      ],
      row_decoder,
    )
  {
    Ok(_) ->
      get_by_id(db, id)
      |> result.try(fn(opt) {
        case opt {
          Some(rating) -> Ok(rating)
          None -> Error(db.QueryError("Failed to retrieve created rating"))
        }
      })
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Get a rating by ID
pub fn get_by_id(
  db: db.Connection,
  id: String,
) -> Result(Option(DrinkRating), db.DbError) {
  let sql = "SELECT id, drink_id, user_id, overall_score, sweetness, boba_texture, tea_strength, review_text, created_at, updated_at FROM drink_ratings WHERE id = ?"

  let row_decoder: Decoder(DrinkRating) = drink_rating_decoder()

  case sqlight.query(sql, db.conn, [sqlight.text(id)], row_decoder) {
    Ok(ratings) ->
      case list.first(ratings) {
        Ok(rating) -> Ok(Some(rating))
        Error(_) -> Ok(None)
      }
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Get rating by drink and user (unique constraint)
pub fn get_by_drink_and_user(
  db: db.Connection,
  drink_id: String,
  user_id: String,
) -> Result(Option(DrinkRating), db.DbError) {
  let sql = "SELECT id, drink_id, user_id, overall_score, sweetness, boba_texture, tea_strength, review_text, created_at, updated_at FROM drink_ratings WHERE drink_id = ? AND user_id = ?"

  let row_decoder: Decoder(DrinkRating) = drink_rating_decoder()

  case
    sqlight.query(
      sql,
      db.conn,
      [sqlight.text(drink_id), sqlight.text(user_id)],
      row_decoder,
    )
  {
    Ok(ratings) ->
      case list.first(ratings) {
        Ok(rating) -> Ok(Some(rating))
        Error(_) -> Ok(None)
      }
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Get all ratings for a drink
pub fn get_by_drink(
  db: db.Connection,
  drink_id: String,
) -> Result(List(DrinkRating), db.DbError) {
  let sql = "SELECT id, drink_id, user_id, overall_score, sweetness, boba_texture, tea_strength, review_text, created_at, updated_at FROM drink_ratings WHERE drink_id = ? ORDER BY created_at DESC"

  let row_decoder: Decoder(DrinkRating) = drink_rating_decoder()

  case sqlight.query(sql, db.conn, [sqlight.text(drink_id)], row_decoder) {
    Ok(ratings) -> Ok(ratings)
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Get all ratings by a user
pub fn get_by_user(
  db: db.Connection,
  user_id: String,
) -> Result(List(DrinkRating), db.DbError) {
  let sql = "SELECT id, drink_id, user_id, overall_score, sweetness, boba_texture, tea_strength, review_text, created_at, updated_at FROM drink_ratings WHERE user_id = ? ORDER BY created_at DESC"

  let row_decoder: Decoder(DrinkRating) = drink_rating_decoder()

  case sqlight.query(sql, db.conn, [sqlight.text(user_id)], row_decoder) {
    Ok(ratings) -> Ok(ratings)
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Update a rating
pub fn update(
  db: db.Connection,
  id: String,
  overall_score: Int,
  sweetness: Int,
  boba_texture: Int,
  tea_strength: Int,
  review_text: Option(String),
) -> Result(DrinkRating, db.DbError) {
  let sql = "UPDATE drink_ratings SET overall_score = ?, sweetness = ?, boba_texture = ?, tea_strength = ?, review_text = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?"

  let review = option.unwrap(review_text, "")
  let row_decoder: Decoder(Int) = decode.int

  case
    sqlight.query(
      sql,
      db.conn,
      [
        sqlight.int(overall_score),
        sqlight.int(sweetness),
        sqlight.int(boba_texture),
        sqlight.int(tea_strength),
        sqlight.text(review),
        sqlight.text(id),
      ],
      row_decoder,
    )
  {
    Ok(_) ->
      get_by_id(db, id)
      |> result.try(fn(opt) {
        case opt {
          Some(rating) -> Ok(rating)
          None -> Error(db.QueryError("Failed to retrieve updated rating"))
        }
      })
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}

/// Delete a rating
pub fn delete(db: db.Connection, id: String) -> Result(Bool, db.DbError) {
  let sql = "DELETE FROM drink_ratings WHERE id = ?"
  let row_decoder: Decoder(Int) = decode.int

  case sqlight.query(sql, db.conn, [sqlight.text(id)], row_decoder) {
    Ok(_) -> Ok(True)
    Error(err) -> Error(db.QueryError(sqlight_error_to_string(err)))
  }
}
