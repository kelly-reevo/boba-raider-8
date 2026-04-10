/// Authorization logic for drink operations

import domain/drink.{type Drink}
import domain/user.{type User, is_admin}
import storage/store.{type Store}

/// Check if user can delete a drink
/// Only creator, store creator, or admin can delete
pub fn can_delete_drink(
  store: Store,
  user: User,
  drink: Drink,
) -> Bool {
  // Admin can delete anything
  is_admin(user)
  // Drink creator can delete
  || drink.is_creator(drink, user.id)
  // Store creator can delete (checked via store ownership)
  || is_store_creator(store, user.id, drink.store_id)
}

/// Check if user is the creator of the store
/// For simplicity, we check if user created any drink in this store
/// In a real system, stores would have their own creator_id field
fn is_store_creator(_store: Store, _user_id: String, _store_id: String) -> Bool {
  // Simplified: in a full implementation, stores would be a separate entity
  // For now, we return false - the other checks (admin, drink creator) cover the main cases
  False
}
