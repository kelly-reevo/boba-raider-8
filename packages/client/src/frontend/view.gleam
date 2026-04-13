import gleam/int
import gleam/list
import frontend/create_drink_form.{type CreateDrinkForm}
import frontend/model.{type Model}
import frontend/msg.{type Msg, BaseTeaType, CreateDrinkFormFieldUpdate, CreateDrinkFormSubmit, Description, DrinkName, Price, StoreId}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    html.div([attribute.class("counter")], [
      html.button([event.on_click(msg.Decrement)], [element.text("-")]),
      html.span([attribute.class("count")], [
        element.text("Count: " <> int.to_string(model.count)),
      ]),
      html.button([event.on_click(msg.Increment)], [element.text("+")]),
    ]),
    html.button([event.on_click(msg.Reset), attribute.class("reset")], [
      element.text("Reset"),
    ]),
    create_drink_form_view(model.create_drink_form),
  ])
}

/// Create Drink Form component view
fn create_drink_form_view(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("create-drink-form-container")], [
    html.h2([], [element.text("Create New Drink")]),
    create_drink_form_error_alert(form),
    html.form(
      [
        attribute.class("create-drink-form"),
        attribute.attribute("data-testid", "create-drink-form"),
        event.on_submit(fn(_) { CreateDrinkFormSubmit }),
      ],
      [
        store_id_field(form),
        drink_name_field(form),
        description_field(form),
        tea_type_dropdown(form),
        price_field(form),
        submit_button(form),
      ]
    ),
  ])
}

/// Store ID field (hidden or select depending on context)
fn store_id_field(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([attribute.for("store_id")], [element.text("Store")]),
    html.select(
      [
        attribute.name("store_id"),
        attribute.id("store_id"),
        attribute.required(True),
        attribute.value(form.store_id),
        event.on_input(fn(value) { CreateDrinkFormFieldUpdate(StoreId, value) }),
      ],
      [
        html.option([attribute.value(""), attribute.disabled(True), attribute.selected(form.store_id == "")], "Select a store"),
        // Store options would be populated dynamically
      ]
    ),
    store_id_error(form),
  ])
}

/// Show store_id validation error
fn store_id_error(form: CreateDrinkForm) -> Element(Msg) {
  case list.any(form.field_errors, fn(e) { e == create_drink_form.StoreIdRequired }) {
    True -> html.div([attribute.class("field-error"), attribute.attribute("data-testid", "store-id-error")], [element.text("Store is required")])
    False -> element.none()
  }
}

/// Drink name input field
fn drink_name_field(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([attribute.for("name")], [element.text("Drink Name *")]),
    html.input([
      attribute.type_("text"),
      attribute.name("name"),
      attribute.id("name"),
      attribute.required(True),
      attribute.placeholder("Enter drink name"),
      attribute.value(form.name),
      attribute.class(case list.any(form.field_errors, fn(e) { e == create_drink_form.NameRequired }) {
        True -> "error"
        False -> ""
      }),
      event.on_input(fn(value) { CreateDrinkFormFieldUpdate(DrinkName, value) }),
    ]),
    name_error(form),
  ])
}

/// Show name validation error
fn name_error(form: CreateDrinkForm) -> Element(Msg) {
  case list.any(form.field_errors, fn(e) { e == create_drink_form.NameRequired }) {
    True -> html.div([attribute.class("field-error visible"), attribute.attribute("data-testid", "name-error")], [element.text("Drink name is required")])
    False -> element.none()
  }
}

/// Description textarea field
fn description_field(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([attribute.for("description")], [element.text("Description")]),
    html.textarea(
      [
        attribute.name("description"),
        attribute.id("description"),
        attribute.placeholder("Enter description (optional)"),
        attribute.rows(3),
        attribute.value(form.description),
        event.on_input(fn(value) { CreateDrinkFormFieldUpdate(Description, value) }),
      ],
      ""
    ),
  ])
}

/// Tea type dropdown with enum options
fn tea_type_dropdown(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([attribute.for("base_tea_type")], [element.text("Base Tea Type")]),
    html.select(
      [
        attribute.name("base_tea_type"),
        attribute.id("base_tea_type"),
        attribute.value(form.base_tea_type),
        event.on_input(fn(value) { CreateDrinkFormFieldUpdate(BaseTeaType, value) }),
      ],
      [
        html.option([attribute.value(""), attribute.disabled(True), attribute.selected(form.base_tea_type == "")], "Select Tea Type"),
        html.option([attribute.value("Black")], "Black"),
        html.option([attribute.value("Green")], "Green"),
        html.option([attribute.value("Oolong")], "Oolong"),
        html.option([attribute.value("White")], "White"),
        html.option([attribute.value("Milk")], "Milk"),
      ]
    ),
  ])
}

/// Price input field
fn price_field(form: CreateDrinkForm) -> Element(Msg) {
  html.div([attribute.class("form-field")], [
    html.label([attribute.for("price")], [element.text("Price")]),
    html.input([
      attribute.type_("number"),
      attribute.name("price"),
      attribute.id("price"),
      attribute.placeholder("0.00"),
      attribute.step("0.01"),
      attribute.min("0.01"),
      attribute.value(form.price),
      attribute.class(case list.any(form.field_errors, fn(e) { e == create_drink_form.PriceInvalid }) {
        True -> "error"
        False -> ""
      }),
      event.on_input(fn(value) { CreateDrinkFormFieldUpdate(Price, value) }),
    ]),
    price_error(form),
  ])
}

/// Show price validation error
fn price_error(form: CreateDrinkForm) -> Element(Msg) {
  case list.any(form.field_errors, fn(e) { e == create_drink_form.PriceInvalid }) {
    True -> html.div([attribute.class("field-error visible"), attribute.attribute("data-testid", "price-error")], [element.text("Price must be a positive number")])
    False -> element.none()
  }
}

/// Submit button with state handling
fn submit_button(form: CreateDrinkForm) -> Element(Msg) {
  let button_text = case form.state {
    create_drink_form.Submitting -> "Creating..."
    _ -> "Create Drink"
  }

  html.div([attribute.class("form-actions")], [
    html.button(
      [
        attribute.type_("submit"),
        attribute.class("submit-button"),
        attribute.disabled(form.state == create_drink_form.Submitting || !create_drink_form.is_valid(form)),
      ],
      [element.text(button_text)]
    ),
  ])
}

/// Display global form error message
fn create_drink_form_error_alert(form: CreateDrinkForm) -> Element(Msg) {
  case form.state {
    create_drink_form.Failed(error) ->
      html.div([attribute.class("form-error visible"), attribute.attribute("data-testid", "form-error")], [element.text(error)])
    _ -> element.none()
  }
}
