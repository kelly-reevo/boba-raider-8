import frontend/model.{type Model, Model, CreateStorePage, HomePage}
import frontend/msg.{type Msg, CreateStoreMsg, NavigateToCreateStore, NavigateToHome}
import frontend/pages/create_store_msg
import frontend/pages/create_store_page
import lustre/effect.{type Effect}

/// Main application update function
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Navigation
    NavigateToCreateStore -> {
      let new_model = Model(..model, current_page: CreateStorePage(create_store_msg.init()))
      #(new_model, effect.none())
    }

    NavigateToHome -> {
      let new_model = Model(..model, current_page: HomePage)
      #(new_model, effect.none())
    }

    // Route page-specific messages
    CreateStoreMsg(page_msg) -> {
      case model.current_page {
        CreateStorePage(state) -> {
          let #(new_state, page_effect) = create_store_page.update(state, page_msg)
          let new_page = CreateStorePage(new_state)
          let new_model = Model(..model, current_page: new_page)

          // Handle navigation from page (e.g., on success)
          let nav_effect = case new_state {
            create_store_msg.Success(_store_id) -> {
              // Redirect to store detail page
              effect.from(fn(_dispatch) {
                // In real implementation: window.location.href = "/stores/" <> store_id
                Nil
              })
            }
            _ -> effect.none()
          }

          // Map page effect to global effect and combine with nav effect
          let mapped_effect = effect.map(page_effect, fn(m) { CreateStoreMsg(m) })
          #(new_model, effect.batch([mapped_effect, nav_effect]))
        }

        // If we're not on the create store page, ignore the message
        _ -> #(model, effect.none())
      }
    }
  }
}
