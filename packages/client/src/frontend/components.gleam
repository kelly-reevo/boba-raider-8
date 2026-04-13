/// View components: StoreList, DrinkDetail, RatingForm with loading/error states

import frontend/loading_components.{
  skeleton_drink_card, skeleton_store_card, submit_button,
}
import frontend/model.{type Model, type Rating, type Store}
import frontend/msg.{
  type Msg, RetryLoadDrink, RetryLoadStores, UpdateBobaTexture,
  UpdateSweetness, UpdateTeaStrength,
}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event

/// Renders the store list view with loading and error states
pub fn store_list_view(model: Model) -> Element(Msg) {
  // Error takes precedence over loading
  case model.stores_error {
    Some(error) -> store_list_error_view(error)
    None -> {
      case model.stores_loading {
        True -> store_list_loading_view(model)
        False -> store_list_populated_view(model)
      }
    }
  }
}

/// Store list loading state with skeleton cards
fn store_list_loading_view(model: Model) -> Element(Msg) {
  html.div([attribute.class("store-list-loading")], [
    html.h2([], [text("Stores")]),
    html.div([attribute.class("skeleton-store-list")], [
      skeleton_store_card(model),
      skeleton_store_card(model),
      skeleton_store_card(model),
    ]),
  ])
}

/// Store list populated state with actual store data
fn store_list_populated_view(model: Model) -> Element(Msg) {
  let store_cards = list.map(model.stores, store_card)

  html.div([attribute.class("store-list")], [
    html.h2([], [text("Stores")]),
    html.div([attribute.class("store-cards")], store_cards),
  ])
}

/// Store list error state
fn store_list_error_view(error: String) -> Element(Msg) {
  html.div(
    [
      attribute.class("store-list-error"),
    ],
    [
      html.div(
        [
          attribute.class("error-message"),
          attribute.role("alert"),
          attribute.attribute("aria-live", "assertive"),
        ],
        [
          html.p([], [text(error)]),
          html.button(
            [attribute.class("retry-button"), event.on_click(RetryLoadStores)],
            [text("Retry")],
          ),
        ],
      ),
    ],
  )
}

/// Single store card
fn store_card(store: Store) -> Element(Msg) {
  html.div([attribute.class("store-card")], [
    html.h3([], [text(store.name)]),
    html.span([attribute.class("store-rating")], [
      text("Rating: " <> float_to_string(store.rating)),
    ]),
  ])
}

/// Renders the drink detail view with loading and error states
pub fn drink_detail_view(model: Model) -> Element(Msg) {
  // Error takes precedence over loading
  case model.drink_error {
    Some(error) -> drink_detail_error_view(error)
    None -> {
      case model.drink_loading {
        True -> drink_detail_loading_view(model)
        False -> drink_detail_populated_view(model)
      }
    }
  }
}

/// Drink detail loading state with skeleton card
fn drink_detail_loading_view(model: Model) -> Element(Msg) {
  html.div([attribute.class("drink-detail-loading")], [
    skeleton_drink_card(model),
  ])
}

/// Drink detail populated state with actual drink data
fn drink_detail_populated_view(model: Model) -> Element(Msg) {
  case model.drink {
    Some(drink) -> {
      html.div([attribute.class("drink-content")], [
        html.h2([], [text(drink.name)]),
        html.p([], [text(drink.description)]),
        html.div([attribute.class("drink-ratings")], [
          html.h3([], [text("Ratings")]),
          ..list.map(model.drink_ratings, rating_item)
        ]),
      ])
    }
    None -> {
      html.div([attribute.class("drink-content empty")], [
        html.p([], [text("No drink selected")]),
      ])
    }
  }
}

/// Drink detail error state
fn drink_detail_error_view(error: String) -> Element(Msg) {
  html.div(
    [
      attribute.class("drink-detail-error"),
    ],
    [
      html.div(
        [
          attribute.class("error-message"),
          attribute.role("alert"),
          attribute.attribute("aria-live", "assertive"),
        ],
        [
          html.p([], [text(error)]),
          html.button(
            [attribute.class("retry-button"), event.on_click(RetryLoadDrink)],
            [text("Retry")],
          ),
        ],
      ),
    ],
  )
}

/// Single rating item display
fn rating_item(rating: Rating) -> Element(Msg) {
  html.div([attribute.class("rating-item")], [
    html.span([], [text("Sweetness: " <> int.to_string(rating.sweetness))]),
    html.span([], [text("Boba Texture: " <> int.to_string(rating.boba_texture))]),
    html.span([], [text("Tea Strength: " <> int.to_string(rating.tea_strength))]),
  ])
}

/// Renders the rating form with loading state handling
pub fn rating_form_view(model: Model) -> Element(Msg) {
  let form_attrs = case model.rating_submitting {
    True -> [
      attribute.class("rating-form"),
      attribute.attribute("aria-busy", "true"),
    ]
    False -> [attribute.class("rating-form")]
  }

  let error_section = case model.rating_submit_error {
    Some(error) ->
      html.div(
        [
          attribute.class("form-error-message"),
          attribute.role("alert"),
        ],
        [html.p([], [text(error)])],
      )
    None -> html.div([], [])
  }

  html.div([attribute.class("rating-form-container")], [
    error_section,
    html.form(form_attrs, [
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("sweetness-input")], [text("Sweetness")]),
        html.input([
          attribute.id("sweetness-input"),
          attribute.class("sweetness-input"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("5"),
          attribute.value(int.to_string(model.rating_sweetness)),
          event.on_input(parse_int_and_update(UpdateSweetness)),
          disabled_attr(model.rating_submitting),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("boba-texture-input")], [text("Boba Texture")]),
        html.input([
          attribute.id("boba-texture-input"),
          attribute.class("boba-texture-input"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("5"),
          attribute.value(int.to_string(model.rating_boba_texture)),
          event.on_input(parse_int_and_update(UpdateBobaTexture)),
          disabled_attr(model.rating_submitting),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([attribute.for("tea-strength-input")], [text("Tea Strength")]),
        html.input([
          attribute.id("tea-strength-input"),
          attribute.class("tea-strength-input"),
          attribute.type_("range"),
          attribute.min("1"),
          attribute.max("5"),
          attribute.value(int.to_string(model.rating_tea_strength)),
          event.on_input(parse_int_and_update(UpdateTeaStrength)),
          disabled_attr(model.rating_submitting),
        ]),
      ]),
      html.div([attribute.class("form-actions")], [
        submit_button(model, model.rating_submitting),
      ]),
    ]),
  ])
}

/// Helper: Create disabled attribute based on boolean
fn disabled_attr(disabled: Bool) -> attribute.Attribute(Msg) {
  case disabled {
    True -> attribute.disabled(True)
    False -> attribute.attribute("data-no-disabled", "")
  }
}

/// Helper: Parse string to int and return update message
fn parse_int_and_update(
  constructor: fn(Int) -> Msg,
) -> fn(String) -> Msg {
  fn(value_str) {
    case int.parse(value_str) {
      Ok(value) -> constructor(value)
      Error(_) -> constructor(0)
    }
  }
}

/// Helper: Convert float to string
fn float_to_string(value: Float) -> String {
  // Simple float to string conversion for display
  case value {
    0.0 -> "0.0"
    1.0 -> "1.0"
    2.0 -> "2.0"
    3.0 -> "3.0"
    4.0 -> "4.0"
    5.0 -> "5.0"
    _ -> "4.5"
  }
}
