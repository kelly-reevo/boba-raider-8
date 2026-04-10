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
