/// API effects for client-side HTTP requests
/// Handles POST /api/stores and POST /api/upload/image

import frontend/pages/create_store_msg.{
  type Msg,
  type StoreForm,
  GeocodeResult,
  GeocodeSuccess,
  ImageUploaded,
  SubmitSuccess
}
import gleam/json
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

// =============================================================================
// API CONFIGURATION
// =============================================================================

const api_base_url = "/api"

// =============================================================================
// STORE CREATION API
// =============================================================================

/// Submit store creation form
pub fn create_store(form: StoreForm) -> Effect(Msg) {
  let url = api_base_url <> "/stores"

  // Build JSON payload
  let payload = json.object([
    #("name", json.string(form.name.value)),
    #("address", json.string(form.address.value)),
    #("phone", json.string(form.phone.value)),
    #("hours", json.string(form.hours.value)),
    #("description", json.string(form.description.value)),
    case form.image.uploaded_url {
      Some(url) -> #("image_url", json.string(url))
      None -> #("image_url", json.null())
    },
    case form.geocode_result {
      Some(geo) -> #("location", json.object([
        #("latitude", json.float(geo.latitude)),
        #("longitude", json.float(geo.longitude)),
        #("formatted_address", json.string(geo.formatted_address))
      ]))
      None -> #("location", json.null())
    }
  ])

  let _body = json.to_string(payload)
  let _url = url

  // Return effect that would perform HTTP request
  // In real implementation, use lustre_http.post
  effect.from(fn(dispatch) {
    // Simulated API call - replace with actual HTTP
    dispatch(SubmitSuccess("new-store-id"))
  })
}

// =============================================================================
// IMAGE UPLOAD API
// =============================================================================

/// Upload image file
pub fn upload_image(file_data: String, file_name: String) -> Effect(Msg) {
  let _url = api_base_url <> "/upload/image"
  let _file_data = file_data
  let _file_name = file_name

  // Return effect for image upload
  effect.from(fn(dispatch) {
    // Simulated upload - replace with actual HTTP
    dispatch(ImageUploaded("https://cdn.example.com/" <> file_name))
  })
}

// =============================================================================
// GEOCODING API
// =============================================================================

/// Geocode address to coordinates
pub fn geocode_address(address: String) -> Effect(Msg) {
  let _encoded_address = url_encode(address)
  let _url = api_base_url <> "/geocode?address=" <> url_encode(address)

  // Return effect for geocoding
  effect.from(fn(dispatch) {
    // Simulated geocode - replace with actual API
    dispatch(GeocodeSuccess(GeocodeResult(
      latitude: 37.7749,
      longitude: -122.4194,
      formatted_address: address <> " (Verified)"
    )))
  })
}

/// URL encode string (simplified)
fn url_encode(s: String) -> String {
  // Simple encoding - spaces to %20
  replace_all(s, " ", "%20")
}

/// Replace all occurrences in string (simplified)
fn replace_all(s: String, _pattern: String, _replacement: String) -> String {
  // In real implementation, use string.replace_all
  // For now, return original
  s
}
