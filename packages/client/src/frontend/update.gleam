import frontend/create_drink_form
import frontend/effects
import frontend/model.{type Model, Model}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages
    msg.Increment -> #(Model(..model, count: model.count + 1), effect.none())
    msg.Decrement -> #(Model(..model, count: model.count - 1), effect.none())
    msg.Reset -> #(Model(..model, count: 0), effect.none())

    // Create Drink Form field updates
    msg.CreateDrinkFormFieldUpdate(field, value) -> {
      let current_form = model.create_drink_form
      let updated_form = case field {
        msg.StoreId -> create_drink_form.CreateDrinkForm(..current_form, store_id: value)
        msg.DrinkName -> create_drink_form.CreateDrinkForm(..current_form, name: value)
        msg.Description -> create_drink_form.CreateDrinkForm(..current_form, description: value)
        msg.BaseTeaType -> create_drink_form.CreateDrinkForm(..current_form, base_tea_type: value)
        msg.Price -> create_drink_form.CreateDrinkForm(..current_form, price: value)
      }
      #(Model(..model, create_drink_form: updated_form), effect.none())
    }

    // Form submission
    msg.CreateDrinkFormSubmit -> {
      let current_form = model.create_drink_form

      // Validate form before submission
      let validation_errors = create_drink_form.validate_form(current_form)
      let form_is_valid = create_drink_form.is_valid(current_form)

      case validation_errors {
        [] -> {
          case form_is_valid {
            True -> {
              // Valid form - submit to API
              let form_with_state = create_drink_form.CreateDrinkForm(
                ..current_form,
                state: create_drink_form.Submitting,
                field_errors: [],
              )
              let updated_model = Model(..model, create_drink_form: form_with_state)
              let effect = effects.submit_create_drink(
                current_form.store_id,
                current_form.name,
                current_form.description,
                current_form.base_tea_type,
                current_form.price,
              )
              #(updated_model, effect)
            }
            False -> {
              // Invalid form - show validation errors
              let form_with_errors = create_drink_form.CreateDrinkForm(
                ..current_form,
                field_errors: validation_errors,
              )
              #(Model(..model, create_drink_form: form_with_errors), effect.none())
            }
          }
        }
        _ -> {
          // Invalid form - show validation errors
          let form_with_errors = create_drink_form.CreateDrinkForm(
            ..current_form,
            field_errors: validation_errors,
          )
          #(Model(..model, create_drink_form: form_with_errors), effect.none())
        }
      }
    }

    // API success response
    msg.CreateDrinkFormSubmitSuccess(drink_id) -> {
      let current_form = model.create_drink_form
      let updated_form = create_drink_form.CreateDrinkForm(
        ..current_form,
        state: create_drink_form.Succeeded(drink_id),
      )
      #(Model(..model, create_drink_form: updated_form), effect.none())
    }

    // API error response
    msg.CreateDrinkFormSubmitError(error) -> {
      let current_form = model.create_drink_form
      let updated_form = create_drink_form.CreateDrinkForm(
        ..current_form,
        state: create_drink_form.Failed(error),
      )
      #(Model(..model, create_drink_form: updated_form), effect.none())
    }
  }
}
