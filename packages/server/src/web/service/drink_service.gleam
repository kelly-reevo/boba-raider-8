/// Drink service - business logic for drink operations
/// Handles authorization and data access

import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import shared.{NotFound, InvalidInput}
import web/model/drink.{
  type Drink, type DrinkUpdate, type User, User, Admin, StoreCreator, Regular,
}

/// Storage type - represents data access layer
/// For now, using simple in-memory stub. Replace with database calls.
pub opaque type DrinkStore {
  DrinkStore(
    get_drink: fn(String) -> Option(Drink),
    update_drink: fn(Drink) -> Result(Nil, String),
  )
}

/// Create a new store instance
/// In production, this would initialize database connections
pub fn new_store() -> DrinkStore {
  DrinkStore(
    get_drink: fn(_) { None },
    update_drink: fn(_) { Ok(Nil) },
  )
}

/// Update drink operation
/// Returns the updated drink on success, or an error
pub fn update_drink(
  store: DrinkStore,
  user: User,
  drink_id: String,
  update: DrinkUpdate,
) -> Result(Drink, shared.AppError) {
  // 1. Check if drink exists
  let drink_opt = store.get_drink(drink_id)
  case drink_opt {
    None -> Error(NotFound("Drink not found"))
    Some(drink) -> {
      // 2. Check authorization
      case drink.can_modify(user, drink) {
        False -> {
          Error(InvalidInput("Forbidden: insufficient permissions"))
        }
        True -> {
          // 3. Apply updates
          let updated = drink.apply_update(drink, update)

          // 4. Persist changes
          case store.update_drink(updated) {
            Ok(_) -> Ok(updated)
            Error(msg) -> Error(shared.InternalError(msg))
          }
        }
      }
    }
  }
}

/// Get a single drink by ID
pub fn get_drink(store: DrinkStore, drink_id: String) -> Option(Drink) {
  store.get_drink(drink_id)
}

/// Mock store for testing - pre-populated with test data
pub fn mock_store_with_drinks(drinks: List(Drink)) -> DrinkStore {
  let drink_map = build_drink_map(drinks, dict.new())

  DrinkStore(
    get_drink: fn(id) { dict.get(drink_map, id) |> option.from_result },
    update_drink: fn(_drink) {
      // In mock, just succeed - real implementation would update DB
      Ok(Nil)
    },
  )
}

/// Build lookup map from drink list
fn build_drink_map(
  drinks: List(Drink),
  acc: Dict(String, Drink),
) -> Dict(String, Drink) {
  case drinks {
    [] -> acc
    [first, ..rest] -> build_drink_map(rest, dict.insert(acc, first.id, first))
  }
}

/// Parse user from request context (simplified)
/// In production, this extracts from authenticated session/JWT
pub fn extract_user(_auth_header: Option(String)) -> Option(User) {
  // Stub: always returns a regular user
  // In production, decode JWT/session and extract user info
  Some(User(id: "user-1", role: Regular, store_id: None))
}

/// Check if user has admin role
pub fn is_admin(user: User) -> Bool {
  case user.role {
    Admin -> True
    _ -> False
  }
}

/// Check if user is store creator for given store
pub fn is_store_creator(user: User, store_id: String) -> Bool {
  case user.role, user.store_id {
    StoreCreator, Some(sid) -> sid == store_id
    _, _ -> False
  }
}
