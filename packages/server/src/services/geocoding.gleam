/// Geocoding service for address to coordinates conversion

import gleam/int
import gleam/string
import shared.{type Coordinates, Coordinates}

/// Geocode an address to lat/lng coordinates
/// In production, this would call an external API (Google Maps, Mapbox, etc.)
/// For now, returns mock coordinates based on address hash
pub fn geocode_address(address: String) -> Result(Coordinates, String) {
  // Validate address is not empty
  case string.is_empty(address) {
    True -> Error("Address cannot be empty")
    False -> {
      // Mock geocoding: generate deterministic coordinates from address
      let mock_lat = generate_mock_coordinate(address, 37.0, 42.0)
      let mock_lng = generate_mock_coordinate(address <> "lng", -123.0, -71.0)

      Ok(Coordinates(lat: mock_lat, lng: mock_lng))
    }
  }
}

/// Generate a deterministic mock coordinate from a string
/// Produces values in the range [min, max]
fn generate_mock_coordinate(input: String, min: Float, max: Float) -> Float {
  let hash = hash_string(input)
  let normalized = int.to_float(hash % 1000) /. 1000.0
  min +. { normalized *. { max -. min } }
}

/// Simple string hash function using fold
fn hash_string(input: String) -> Int {
  input
  |> string.to_utf_codepoints
  |> list_fold(0, fn(acc, cp) {
    let char_val = string.utf_codepoint_to_int(cp)
    acc * 31 + char_val
  })
}

/// Custom fold for lists (simplified)
fn list_fold(list: List(a), initial: b, f: fn(b, a) -> b) -> b {
  case list {
    [] -> initial
    [head, ..tail] -> list_fold(tail, f(initial, head), f)
  }
}

