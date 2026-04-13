/// Boba Store - Public API for drink storage operations
/// Re-exports drink_store functionality for test compatibility
import drink_store.{
  type DrinkRecord as DrinkRecord, type DrinkStore as DrinkStore,
}
import gleam/option.{None}

// Re-export start function
pub fn start() {
  drink_store.start()
}

/// Create a new drink
pub fn create_drink(
  store: DrinkStore,
  name: String,
  store_id: Int,
) -> Result(DrinkRecord, String) {
  // The test signature takes name and store_id as separate args
  // Convert store_id Int to String
  let input =
    drink_store.CreateDrinkInput(
      store_id: "store-" <> int_to_string(store_id),
      name: name,
      description: None,
      base_tea_type: None,
      price: None,
    )
  drink_store.create_drink(store, input)
}

/// Helper to convert int to string
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      do_int_to_string(n / 10, digit <> acc)
    }
  }
}
