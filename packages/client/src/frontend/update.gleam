/// State updates

import frontend/effects
import frontend/model.{
  type DrinkFormData, type Model, DrinkFormData, Model, ImageUploadError,
  SubmitError, Submitting, Success, UploadingImage, close_form, open_form,
  reset_form,
}
import frontend/msg.{type Msg}
import gleam/float
import lustre/effect.{type Effect}
import shared.{type CreateDrinkInput, CreateDrinkInput}

/// Main update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Counter messages (original)
    msg.Increment -> {
      let new_model = Model(..model, count: model.count + 1)
      #(new_model, effect.none())
    }
    msg.Decrement -> {
      let new_model = Model(..model, count: model.count - 1)
      #(new_model, effect.none())
    }
    msg.Reset -> {
      let new_model = Model(..model, count: 0)
      #(new_model, effect.none())
    }

    // Form visibility
    msg.OpenCreateDrinkForm(store_id) -> {
      #(open_form(model, store_id), effect.none())
    }

    msg.CloseCreateDrinkForm -> {
      #(close_form(model), effect.none())
    }

    // Form field updates
    msg.UpdateDrinkName(name) -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(..form_data, name: name)
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    msg.UpdateTeaType(tea_type) -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(..form_data, tea_type: tea_type)
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    msg.UpdatePrice(price) -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(..form_data, price: price)
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    msg.UpdateDescription(description) -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(..form_data, description: description)
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    msg.UpdateImageFile(file_data) -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(..form_data, image_file: file_data)
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    msg.ToggleIsSignature -> {
      let form_data = model.form_data
      let new_form_data = DrinkFormData(
        ..form_data,
        is_signature: !form_data.is_signature,
      )
      #(Model(..model, form_data: new_form_data), effect.none())
    }

    // Form submission flow
    msg.SubmitDrinkForm -> {
      // Validate required fields
      case validate_form(model.form_data) {
        Ok(_) -> {
          // Start with image upload if present, otherwise submit directly
          case model.form_data.image_file {
            "" -> {
              // No image, submit directly with empty URL
              let new_model = Model(..model, form_state: Submitting)
              let input = form_to_input(model.form_data, "")
              #(new_model, effects.create_drink(model.store_id, input))
            }
            _ -> {
              // Upload image first
              let new_model = Model(..model, form_state: UploadingImage)
              #(new_model, effects.upload_image(model.form_data.image_file))
            }
          }
        }
        Error(validation_error) -> {
          let new_model = Model(..model, form_state: SubmitError(validation_error))
          #(new_model, effect.none())
        }
      }
    }

    msg.ImageUploaded(result) -> {
      case result {
        Ok(image_url) -> {
          // Image uploaded, now create the drink
          let new_model = Model(..model, form_state: Submitting)
          let input = form_to_input(model.form_data, image_url)
          #(new_model, effects.create_drink(model.store_id, input))
        }
        Error(error) -> {
          let new_model = Model(..model, form_state: ImageUploadError(error))
          #(new_model, effect.none())
        }
      }
    }

    msg.DrinkCreated(result) -> {
      case result {
        Ok(_) -> {
          let new_model = Model(..model, form_state: Success)
          #(new_model, effect.none())
        }
        Error(error) -> {
          let new_model = Model(..model, form_state: SubmitError(error))
          #(new_model, effect.none())
        }
      }
    }

    msg.ResetForm -> {
      #(reset_form(model), effect.none())
    }
  }
}

/// Validate form data
fn validate_form(form_data: DrinkFormData) -> Result(Nil, String) {
  case form_data.name {
    "" -> Error("Name is required")
    _ -> Ok(Nil)
  }
}

/// Convert form data to API input
fn form_to_input(
  form_data: DrinkFormData,
  image_url: String,
) -> CreateDrinkInput {
  let price = case float.parse(form_data.price) {
    Ok(p) -> p
    Error(_) -> 0.0
  }

  CreateDrinkInput(
    name: form_data.name,
    tea_type: form_data.tea_type,
    price: price,
    description: form_data.description,
    image_url: image_url,
    is_signature: form_data.is_signature,
  )
}
