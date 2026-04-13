import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, Some, None}
import gleam/otp/actor
import gleam/string
import store/store_data_access as data_access
import store/store_validation as validation

/// Store record with drink count
pub type StoreWithDrinkCount {
  StoreWithDrinkCount(
    id: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    drink_count: Int,
    created_at: String,
  )
}

/// Input for creating a store (matches boundary contract)
pub type CreateStoreInput {
  CreateStoreInput(
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
  )
}

/// Event types for store operations
pub type StoreEvent {
  StoreCreated(StoreWithDrinkCount)
  StoreUpdated(String)
  StoreDeleted(String)
}

/// Event publisher trait/interface
pub type EventPublisher {
  EventPublisher(publish: fn(String, StoreEvent) -> Nil)
}

/// Actor state for the store service
type ServiceState {
  ServiceState(
    data_access_state: data_access.StoreState,
    event_publisher: Option(EventPublisher),
  )
}

/// Actor message types
pub type StoreServiceMsg {
  CreateStore(CreateStoreInput, Subject(Result(StoreWithDrinkCount, String)))
  GetStoreWithDrinkCount(String, Subject(Result(StoreWithDrinkCount, String)))
  SearchStores(String, Subject(Result(List(StoreWithDrinkCount), String)))
}

pub type StoreService =
  Subject(StoreServiceMsg)

/// Convert data access store to service store with drink count
fn to_store_with_count(
  store: data_access.BobaStore,
  drink_count: Int,
) -> StoreWithDrinkCount {
  StoreWithDrinkCount(
    id: store.id,
    name: store.name,
    address: store.address,
    city: store.city,
    phone: store.phone,
    drink_count: drink_count,
    created_at: store.created_at,
  )
}

/// Count drinks for a store (simplified - in real implementation would query drink store)
fn count_drinks_for_store(_store_id: String) -> Int {
  // This is a placeholder - in production this would query the drink store actor
  // For now, we return 0 as the default for newly created stores
  0
}

/// Actor message handler
fn handle_message(state: ServiceState, msg: StoreServiceMsg) -> actor.Next(ServiceState, StoreServiceMsg) {
  case msg {
    CreateStore(input, reply_to) -> {
      // Validate input first
      let validation_input = validation.CreateStoreInput(
        name: input.name,
        address: input.address,
        city: input.city,
        phone: input.phone,
      )

      case validation.validate_create_input(validation_input) {
        Error(err) -> {
          actor.send(reply_to, Error(err))
          actor.continue(state)
        }
        Ok(_) -> {
          // Convert input to data access format
          let data_input = data_access.CreateStoreInput(
            name: string.trim(input.name),
            address: input.address,
            city: input.city,
            phone: input.phone,
          )

          // Create in data access layer
          let #(new_data_state, created_store) = data_access.create(
            state.data_access_state,
            data_input,
          )

          // Convert to output format with drink count
          let store_with_count = to_store_with_count(created_store, 0)

          // Publish event if publisher exists
          case state.event_publisher {
            Some(publisher) -> {
              publisher.publish("store.created", StoreCreated(store_with_count))
            }
            None -> Nil
          }

          // Update state and reply
          let new_state = ServiceState(
            data_access_state: new_data_state,
            event_publisher: state.event_publisher,
          )
          actor.send(reply_to, Ok(store_with_count))
          actor.continue(new_state)
        }
      }
    }

    GetStoreWithDrinkCount(store_id, reply_to) -> {
      // Validate UUID format
      case validation.validate_store_id(store_id) {
        Error(err) -> {
          actor.send(reply_to, Error(err))
          actor.continue(state)
        }
        Ok(valid_id) -> {
          // Try to get store from data access layer
          case data_access.get_by_id(state.data_access_state, valid_id) {
            Error(data_access.StoreNotFound(_)) -> {
              actor.send(reply_to, Error("Store not found"))
              actor.continue(state)
            }
            Error(data_access.StoreInvalidInput(msg)) -> {
              actor.send(reply_to, Error(msg))
              actor.continue(state)
            }
            Error(data_access.StoreInternalError(msg)) -> {
              actor.send(reply_to, Error(msg))
              actor.continue(state)
            }
            Ok(store) -> {
              // Get drink count for this store
              let drink_count = count_drinks_for_store(store.id)
              let store_with_count = to_store_with_count(store, drink_count)
              actor.send(reply_to, Ok(store_with_count))
              actor.continue(state)
            }
          }
        }
      }
    }

    SearchStores(search_term, reply_to) -> {
      // Validate search term
      case validation.validate_search_term(search_term) {
        Error(err) -> {
          actor.send(reply_to, Error(err))
          actor.continue(state)
        }
        Ok(valid_term) -> {
          // Search in data access layer
          let results = search_stores_in_state(state.data_access_state, valid_term)

          // Convert results to stores with drink counts
          let results_with_count = list.map(results, fn(store) {
            let drink_count = count_drinks_for_store(store.id)
            to_store_with_count(store, drink_count)
          })

          actor.send(reply_to, Ok(results_with_count))
          actor.continue(state)
        }
      }
    }
  }
}

/// Search stores by name or city (case-insensitive)
fn search_stores_in_state(
  state: data_access.StoreState,
  term: String,
) -> List(data_access.BobaStore) {
  let all_stores = data_access.list_all(state)
  let lower_term = string.lowercase(term)

  list.filter(all_stores, fn(store) {
    let name_match = string.contains(string.lowercase(store.name), lower_term)
    let city_match = case store.city {
      Some(city) -> string.contains(string.lowercase(city), lower_term)
      None -> False
    }
    name_match || city_match
  })
}

// Public API

/// Start the store service actor
pub fn start() -> Result(StoreService, String) {
  start_with_publisher(None)
}

/// Start with an optional event publisher
pub fn start_with_publisher(publisher: Option(EventPublisher)) -> Result(StoreService, String) {
  let initial_state = ServiceState(
    data_access_state: data_access.new_state(),
    event_publisher: publisher,
  )

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start store service actor")
  }
}

/// Create a new store
pub fn create_store(
  service: StoreService,
  input: CreateStoreInput,
) -> Result(StoreWithDrinkCount, String) {
  let reply_subject = process.new_subject()
  actor.send(service, CreateStore(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store service")
  }
}

/// Get a store by ID with drink count
pub fn get_store_with_drink_count(
  service: StoreService,
  store_id: String,
) -> Result(StoreWithDrinkCount, String) {
  let reply_subject = process.new_subject()
  actor.send(service, GetStoreWithDrinkCount(store_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store service")
  }
}

/// Search stores by name or city
pub fn search_stores(
  service: StoreService,
  search_term: String,
) -> Result(List(StoreWithDrinkCount), String) {
  let reply_subject = process.new_subject()
  actor.send(service, SearchStores(search_term, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store service")
  }
}
