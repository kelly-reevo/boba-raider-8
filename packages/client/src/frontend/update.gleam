/// State updates

import frontend/effects as fx
import frontend/model.{
  type Model, Model, type EditStoreState, EditStoreState,
  CounterPage, EditStorePage, update_edit_store_state, can_edit_store,
}
import frontend/msg.{
  type Msg, type EditStoreMsg, EditStoreMsg, Increment, Decrement, Reset,
  Navigate, RouteChanged, SubmitForm, UpdateName, UpdateDescription,
  UpdateAddress, UpdatePhone, UpdateEmail, StoreLoaded, StoreUpdated,
  CurrentUserLoaded, CancelEdit, ResetForm,
}
import lustre/effect.{type Effect}
import shared.{
  type Store, type StoreInput, StoreInput, type AppError, type Option, Some, None,
  validate_store_input, has_validation_errors, store_to_input, default_store_input,
}

/// Main application update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Original counter messages
    Increment -> {
      case model.page {
        CounterPage(count, error) -> {
          #(Model(..model, page: CounterPage(count + 1, error)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }

    Decrement -> {
      case model.page {
        CounterPage(count, error) -> {
          #(Model(..model, page: CounterPage(count - 1, error)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }

    Reset -> {
      case model.page {
        CounterPage(_, error) -> {
          #(Model(..model, page: CounterPage(0, error)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }

    // Navigation
    Navigate(_url) -> {
      // Would use lustre_navigator in real implementation
      #(model, effect.none())
    }

    RouteChanged(_route) -> {
      // Would update route and page based on URL
      #(model, effect.none())
    }

    // Edit store page messages
    EditStoreMsg(edit_msg) -> {
      handle_edit_store_msg(model, edit_msg)
    }
  }
}

fn handle_edit_store_msg(model: Model, msg: EditStoreMsg) -> #(Model, Effect(Msg)) {
  case msg {
    // Form field updates - pattern match on the EditStoreMsg variant directly
    UpdateName(value) -> {
      let new_model = update_edit_store_state(model, fn(state) {
        EditStoreState(
          ..state,
          input: StoreInput(..state.input, name: value),
          validation_errors: validate_store_input(state.input),
        )
      })
      #(new_model, effect.none())
    }

    UpdateDescription(value) -> {
      let new_model = update_edit_store_state(model, fn(state) {
        EditStoreState(
          ..state,
          input: StoreInput(..state.input, description: value),
          validation_errors: validate_store_input(state.input),
        )
      })
      #(new_model, effect.none())
    }

    UpdateAddress(value) -> {
      let new_model = update_edit_store_state(model, fn(state) {
        EditStoreState(
          ..state,
          input: StoreInput(..state.input, address: value),
          validation_errors: validate_store_input(state.input),
        )
      })
      #(new_model, effect.none())
    }

    UpdatePhone(value) -> {
      let new_model = update_edit_store_state(model, fn(state) {
        EditStoreState(
          ..state,
          input: StoreInput(..state.input, phone: value),
          validation_errors: validate_store_input(state.input),
        )
      })
      #(new_model, effect.none())
    }

    UpdateEmail(value) -> {
      let new_model = update_edit_store_state(model, fn(state) {
        EditStoreState(
          ..state,
          input: StoreInput(..state.input, email: value),
          validation_errors: validate_store_input(state.input),
        )
      })
      #(new_model, effect.none())
    }

    // Form submission
    SubmitForm -> {
      case model.page {
        EditStorePage(state) -> {
          // Validate before submitting
          let errors = validate_store_input(state.input)
          case has_validation_errors(errors) {
            True -> {
              // Show validation errors, don't submit
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(..s, validation_errors: errors)
              })
              #(new_model, effect.none())
            }
            False -> {
              // Valid form - submit
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(..s, saving: True, save_error: None)
              })
              let fx = fx.update_store(state.store_id, state.input)
              #(new_model, fx)
            }
          }
        }
        _ -> #(model, effect.none())
      }
    }

    // API response handlers
    StoreLoaded(result) -> {
      case result, model.page {
        Ok(store), EditStorePage(_) -> {
          let new_model = update_edit_store_state(model, fn(s) {
            EditStoreState(
              ..s,
              original_store: Some(store),
              input: store_to_input(store),
              loading: False,
              load_error: None,
            )
          })
          #(new_model, effect.none())
        }
        Error(error), EditStorePage(_) -> {
          let error_msg = shared.error_message(error)
          let new_model = update_edit_store_state(model, fn(s) {
            EditStoreState(
              ..s,
              loading: False,
              load_error: Some(error_msg),
            )
          })
          #(new_model, effect.none())
        }
        _, _ -> #(model, effect.none())
      }
    }

    StoreUpdated(result) -> {
      case result, model.page {
        Ok(store), EditStorePage(_) -> {
          // Success - set redirect to store detail page
          let new_model = update_edit_store_state(model, fn(s) {
            EditStoreState(
              ..s,
              saving: False,
              redirect_to: Some("/stores/" <> store.id),
            )
          })
          #(new_model, effect.none())
        }
        Error(error), EditStorePage(_) -> {
          let error_msg = shared.error_message(error)
          let new_model = update_edit_store_state(model, fn(s) {
            EditStoreState(
              ..s,
              saving: False,
              save_error: Some(error_msg),
            )
          })
          #(new_model, effect.none())
        }
        _, _ -> #(model, effect.none())
      }
    }

    CurrentUserLoaded(result) -> {
      case result {
        Ok(user) -> {
          #(Model(..model, current_user: Some(user)), effect.none())
        }
        Error(_) -> {
          // User not logged in - will show unauthorized
          #(model, effect.none())
        }
      }
    }

    // Cancel/reset handlers
    CancelEdit -> {
      case model.page {
        EditStorePage(state) -> {
          case state.original_store {
            Some(store) -> {
              // Navigate back to store detail
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(..s, redirect_to: Some("/stores/" <> store.id))
              })
              #(new_model, effect.none())
            }
            None -> {
              // No original store - navigate to store list
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(..s, redirect_to: Some("/stores"))
              })
              #(new_model, effect.none())
            }
          }
        }
        _ -> #(model, effect.none())
      }
    }

    ResetForm -> {
      case model.page {
        EditStorePage(state) -> {
          case state.original_store {
            Some(store) -> {
              // Reset to original values
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(
                  ..s,
                  input: store_to_input(store),
                  validation_errors: shared.default_validation_errors(),
                  save_error: None,
                )
              })
              #(new_model, effect.none())
            }
            None -> {
              // No original - clear to defaults
              let new_model = update_edit_store_state(model, fn(s) {
                EditStoreState(
                  ..s,
                  input: default_store_input(),
                  validation_errors: shared.default_validation_errors(),
                  save_error: None,
                )
              })
              #(new_model, effect.none())
            }
          }
        }
        _ -> #(model, effect.none())
      }
    }
  }
}

/// Initialize effects when entering edit store page
pub fn init_edit_store(store_id: String) -> Effect(Msg) {
  // Load store data and current user in parallel
  effect.batch([
    fx.fetch_store(store_id),
    fx.fetch_current_user(),
  ])
}
