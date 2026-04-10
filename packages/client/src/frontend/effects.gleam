import frontend/msg.{type Msg, DrinkDetailLoaded}
import lustre/effect.{type Effect}
import shared.{Drink, RatingBreakdown}

/// Fetch drink details and ratings (placeholder implementation)
pub fn load_drink_detail(drink_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // For now, dispatch mock data to demonstrate the component structure
    // In production, this would fetch from the API
    let mock_drink = Drink(
      id: drink_id,
      name: "Brown Sugar Milk Tea",
      shop_name: "Boba Bliss",
      description: "Classic milk tea with brown sugar pearls",
      price: 5.50,
      image_url: "/static/images/drink.jpg",
      average_ratings: RatingBreakdown(
        taste: 4.5,
        texture: 4.2,
        sweetness: 3.8,
        presentation: 4.0,
      ),
    )
    dispatch(DrinkDetailLoaded(mock_drink, []))
  })
}

/// Update a store via PATCH request
pub fn update_store(store_id: String, input: StoreInput) -> Effect(Msg) {
  // In real implementation, uses lustre_http.patch
  let _url = api_base <> "/stores/" <> store_id
  let _body = store_input_to_json(input)
  effect.none()
}

/// Fetch current user for authorization check
pub fn fetch_current_user() -> Effect(Msg) {
  // In real implementation, uses lustre_http.get
  let _url = api_base <> "/me"
  effect.none()
}

// JSON encoder for store input
fn store_input_to_json(input: StoreInput) -> String {
  json.object([
    #("name", json.string(input.name)),
    #("description", json.string(input.description)),
    #("address", json.string(input.address)),
    #("phone", json.string(input.phone)),
    #("email", json.string(input.email)),
  ])
  |> json.to_string()
}
