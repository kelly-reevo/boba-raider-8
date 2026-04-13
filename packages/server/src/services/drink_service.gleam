/// Drink Service - Business logic for drink operations
/// Coordinates data access, validation, and aggregate fetching

import drink_store.{type DrinkRecord, type DrinkStore}
import gleam/option.{type Option, None, Some}
import gleam/string
import rating_service.{type RatingService}
import store/store_data_access as store_access

/// Drink output with embedded store data and rating aggregates
pub type DrinkOutput {
  DrinkOutput(
    id: String,
    store: StoreEmbed,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    rating_count: Int,
    avg_overall: Option(Float),
  )
}

/// Embedded store data in drink output
pub type StoreEmbed {
  StoreEmbed(id: String, name: String)
}

/// Store state type alias for external state management
pub type StoreState = store_access.StoreState

/// Drink creation input at service boundary
pub type CreateDrinkServiceInput {
  CreateDrinkServiceInput(
    store_id: String,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

/// Error types for drink service operations
pub type DrinkServiceError {
  NotFoundError(String)
  ValidationError(String)
  InternalError(String)
}

/// Result type alias for service operations
pub type ServiceResult(a) {
  ServiceResult(Result(a, DrinkServiceError))
}

/// Rating aggregates for a drink
pub type RatingAggregates {
  RatingAggregates(count: Int, avg_overall: Option(Float))
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate drink creation input
fn validate_create_input(input: CreateDrinkServiceInput) -> Result(Nil, DrinkServiceError) {
  // Validate store_id is present and non-empty
  case string.length(string.trim(input.store_id)) > 0 {
    False -> Error(ValidationError("store_id is required"))
    True -> {
      // Validate name is present and non-empty
      case string.length(string.trim(input.name)) > 0 {
        False -> Error(ValidationError("name is required"))
        True -> {
          // Validate price is non-negative if provided
          case input.price {
            Some(p) if p <. 0.0 -> Error(ValidationError("price cannot be negative"))
            _ -> Ok(Nil)
          }
        }
      }
    }
  }
}

/// Validate UUID format
fn validate_uuid(id: String) -> Result(Nil, DrinkServiceError) {
  case string.length(id) > 0 && string.contains(id, "-") {
    True -> Ok(Nil)
    False -> Error(ValidationError("Invalid UUID format"))
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert a DrinkRecord to DrinkOutput with embedded store and empty ratings
fn to_drink_output(
  record: DrinkRecord,
  store: store_access.BobaStore,
  aggregates: RatingAggregates,
) -> DrinkOutput {
  DrinkOutput(
    id: record.id,
    store: StoreEmbed(id: store.id, name: store.name),
    name: record.name,
    description: record.description,
    base_tea_type: record.base_tea_type,
    price: record.price,
    rating_count: aggregates.count,
    avg_overall: aggregates.avg_overall,
  )
}

/// Get empty rating aggregates (for new drinks)
fn empty_aggregates() -> RatingAggregates {
  RatingAggregates(count: 0, avg_overall: None)
}


// ============================================================================
// Store Coordination
// ============================================================================

/// Get store by ID, returning appropriate error if not found
fn get_store_or_error(
  store_state: store_access.StoreState,
  store_id: String,
) -> Result(store_access.BobaStore, DrinkServiceError) {
  case store_access.get_by_id(store_state, store_id) {
    Ok(store) -> Ok(store)
    Error(_) -> Error(NotFoundError("Store not found"))
  }
}

// ============================================================================
// Public Service API
// ============================================================================

/// Create a new drink with validation and store verification
/// Returns drink with embedded store data and empty rating aggregates
pub fn create_drink(
  drink_store_ref: DrinkStore,
  store_state: store_access.StoreState,
  input: CreateDrinkServiceInput,
) -> Result(DrinkOutput, DrinkServiceError) {
  // Step 1: Validate input
  case validate_create_input(input) {
    Error(err) -> Error(err)
    Ok(_) -> {
      // Step 2: Verify store exists
      case get_store_or_error(store_state, input.store_id) {
        Error(err) -> Error(err)
        Ok(store) -> {
          // Step 3: Create drink in data access layer
          let drink_input = drink_store.CreateDrinkInput(
            store_id: input.store_id,
            name: input.name,
            description: input.description,
            base_tea_type: input.base_tea_type,
            price: input.price,
          )

          case drink_store.create_drink(drink_store_ref, drink_input) {
            Ok(record) -> {
              // Step 4: Return with embedded store and empty aggregates
              Ok(to_drink_output(record, store, empty_aggregates()))
            }
            Error(msg) -> Error(InternalError(msg))
          }
        }
      }
    }
  }
}

/// Get a drink by ID with embedded store data and rating aggregates
pub fn get_drink_with_store(
  drink_store_ref: DrinkStore,
  store_state: store_access.StoreState,
  drink_id: String,
) -> Result(DrinkOutput, DrinkServiceError) {
  // Step 1: Validate drink ID
  case validate_uuid(drink_id) {
    Error(err) -> Error(err)
    Ok(_) -> {
      // Step 2: Get drink from data access layer
      case drink_store.get_drink_by_id(drink_store_ref, drink_id) {
        Ok(record) -> {
          // Step 3: Get associated store
          case get_store_or_error(store_state, record.store_id) {
            Error(err) -> Error(err)
            Ok(store) -> {
              // Step 4: Get rating aggregates (extensible - currently returns empty)
              // This is the coordination point for rating service integration
              let aggregates = get_rating_aggregates_for_drink(drink_id)

              // Step 5: Return with embedded store and aggregates
              Ok(to_drink_output(record, store, aggregates))
            }
          }
        }
        Error("Drink not found") -> Error(NotFoundError("Drink not found"))
        Error(msg) -> Error(InternalError(msg))
      }
    }
  }
}

/// Delete a drink by ID, first deleting associated ratings
/// Returns success indicator
pub fn delete_drink(
  drink_store_ref: DrinkStore,
  rating_service_ref: RatingService,
  drink_id: String,
) -> Result(#(Bool, String), DrinkServiceError) {
  // Step 1: Validate drink ID
  case validate_uuid(drink_id) {
    Error(err) -> Error(err)
    Ok(_) -> {
      // Step 2: Verify drink exists before attempting deletion
      case drink_store.get_drink_by_id(drink_store_ref, drink_id) {
        Ok(_) -> {
          // Step 3: Delete associated ratings
          case delete_associated_ratings(rating_service_ref, drink_id) {
            Error(err) -> Error(err)
            Ok(_) -> {
              // Step 4: Delete the drink
              case drink_store.delete_drink(drink_store_ref, drink_id) {
                Ok(True) -> Ok(#(True, drink_id))
                Ok(False) -> Error(InternalError("Failed to delete drink"))
                Error(msg) -> Error(InternalError(msg))
              }
            }
          }
        }
        Error("Drink not found") -> Error(NotFoundError("Drink not found"))
        Error(msg) -> Error(InternalError(msg))
      }
    }
  }
}

// ============================================================================
// Extension Points for Rating Service Integration
// ============================================================================

/// Get rating aggregates for a drink
/// Extensible: Replace with actual rating service call when available
fn get_rating_aggregates_for_drink(_drink_id: String) -> RatingAggregates {
  // Extension point: Coordinate with rating service
  // Current implementation returns empty aggregates for extensibility
  // Future: Call rating_data_access.get_aggregates_for_drink(drink_id)
  empty_aggregates()
}

/// Delete all ratings associated with a drink
fn delete_associated_ratings(
  rating_service_ref: RatingService,
  drink_id: String,
) -> Result(Nil, DrinkServiceError) {
  case rating_service.delete_ratings_for_drink(rating_service_ref, drink_id) {
    Ok(_) -> Ok(Nil)
    Error(msg) -> Error(InternalError("Failed to delete associated ratings: " <> msg))
  }
}
