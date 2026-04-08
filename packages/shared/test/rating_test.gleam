import gleam/json
import gleeunit/should
import rating

pub fn rating_roundtrip_test() {
  let r =
    rating.Rating(
      id: "r1",
      user_id: "u1",
      drink_id: "d1",
      sweetness_score: 4,
      boba_texture_score: 5,
      tea_strength_score: 3,
      overall_score: 4,
      review_text: "Great boba texture",
    )

  r
  |> rating.encoder
  |> json.to_string
  |> json.parse(rating.decoder())
  |> should.be_ok
  |> should.equal(r)
}

pub fn rating_decoder_missing_field_test() {
  "{\"id\": \"r1\"}"
  |> json.parse(rating.decoder())
  |> should.be_error
}

pub fn rating_encoder_fields_test() {
  let r =
    rating.Rating(
      id: "r1",
      user_id: "u1",
      drink_id: "d1",
      sweetness_score: 1,
      boba_texture_score: 2,
      tea_strength_score: 3,
      overall_score: 5,
      review_text: "",
    )

  let json_str = r |> rating.encoder |> json.to_string

  // Decode back and verify individual fields
  let assert Ok(decoded) = json.parse(json_str, rating.decoder())
  should.equal(decoded.sweetness_score, 1)
  should.equal(decoded.boba_texture_score, 2)
  should.equal(decoded.tea_strength_score, 3)
  should.equal(decoded.overall_score, 5)
  should.equal(decoded.review_text, "")
}
