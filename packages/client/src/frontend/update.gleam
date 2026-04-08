import frontend/effects
import frontend/model.{
  type Model, Failed, FormReady, Loaded, LoginPage, Model, ProfilePage,
  RatingPage, RegisterPage, StoreDetailPage, StoreListPage, SubmitError,
  SubmitSuccess, Submitting,
}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import shared

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // Navigation
    msg.GoToLogin -> #(
      Model(..model, page: LoginPage, error: ""),
      effect.none(),
    )
    msg.GoToRegister -> #(
      Model(..model, page: RegisterPage, error: ""),
      effect.none(),
    )
    msg.GoToProfile -> #(Model(..model, page: ProfilePage), effect.none())
    msg.GoToStoreList -> #(
      Model(..model, page: StoreListPage),
      effects.fetch_stores(),
    )
    msg.GoToStoreDetail(store_id) -> #(
      Model(
        ..model,
        page: StoreDetailPage(store_id),
        store: None,
        drinks: [],
        loading: True,
        error: "",
      ),
      effects.fetch_store_detail(store_id),
    )
    msg.GoToRating -> #(
      Model(..model, page: RatingPage),
      effect.none(),
    )

    // Form inputs
    msg.SetEmail(value) -> #(Model(..model, email: value), effect.none())
    msg.SetPassword(value) -> #(Model(..model, password: value), effect.none())
    msg.SetUsername(value) -> #(Model(..model, username: value), effect.none())

    // Auth actions
    msg.SubmitLogin -> #(
      Model(..model, loading: True, error: ""),
      effects.login(model.email, model.password),
    )
    msg.SubmitRegister -> #(
      Model(..model, loading: True, error: ""),
      effects.register(model.username, model.email, model.password),
    )
    msg.Logout -> #(
      model.default(),
      effects.clear_token(),
    )

    // Auth API responses
    msg.GotAuth(Ok(auth_response)) -> #(
      Model(
        ..model,
        token: Some(auth_response.token),
        user: Some(auth_response.user),
        page: ProfilePage,
        loading: False,
        error: "",
        password: "",
      ),
      effects.save_token(auth_response.token),
    )
    msg.GotAuth(Error(err)) -> #(
      Model(..model, loading: False, error: err),
      effect.none(),
    )
    msg.GotProfile(Ok(user)) -> #(
      Model(..model, user: Some(user), loading: False, error: ""),
      effect.none(),
    )
    msg.GotProfile(Error(err)) -> #(
      Model(..model, loading: False, error: err, token: None, user: None),
      effects.clear_token(),
    )

    // Session restore
    msg.GotSavedToken(token) -> #(
      Model(..model, token: Some(token), loading: True, page: ProfilePage),
      effects.fetch_profile(token),
    )

    // Store listing
    msg.UserUpdatedSearch(query) -> #(
      Model(..model, search_query: query),
      effect.none(),
    )
    msg.ApiReturnedStores(Ok(stores)) -> #(
      Model(..model, stores: stores, store_load_state: Loaded),
      effect.none(),
    )
    msg.ApiReturnedStores(Error(err)) -> #(
      Model(..model, store_load_state: Failed(err)),
      effect.none(),
    )

    // Store detail
    msg.GotStore(Ok(store)) -> {
      let loading = model.drinks == []
      #(Model(..model, store: Some(store), loading: loading), effect.none())
    }
    msg.GotStore(Error(_)) -> #(
      Model(..model, loading: False, error: "Failed to load store details"),
      effect.none(),
    )
    msg.GotDrinks(Ok(drinks)) -> {
      let loading = model.store == None
      #(Model(..model, drinks: drinks, loading: loading), effect.none())
    }
    msg.GotDrinks(Error(_)) -> #(
      Model(..model, loading: False, error: "Failed to load drink menu"),
      effect.none(),
    )

    // Rating submission
    msg.SetRating(category, value) -> {
      let clamped = clamp(value, 1, 5)
      let rating = case category {
        msg.Sweetness ->
          shared.RatingSubmission(..model.rating, sweetness: clamped)
        msg.BobaTexture ->
          shared.RatingSubmission(..model.rating, boba_texture: clamped)
        msg.TeaStrength ->
          shared.RatingSubmission(..model.rating, tea_strength: clamped)
        msg.Overall ->
          shared.RatingSubmission(..model.rating, overall: clamped)
      }
      #(Model(..model, rating: rating, rating_page: FormReady), effect.none())
    }

    msg.SubmitRating -> {
      case shared.is_rating_complete(model.rating) {
        True -> #(
          Model(..model, rating_page: Submitting),
          effects.submit_rating(model.rating),
        )
        False -> #(
          Model(..model, rating_page: SubmitError("All ratings are required")),
          effect.none(),
        )
      }
    }

    msg.RatingSubmitted(Ok(_)) -> #(
      Model(..model, rating_page: SubmitSuccess),
      effect.none(),
    )

    msg.RatingSubmitted(Error(err)) -> #(
      Model(..model, rating_page: SubmitError(err)),
      effect.none(),
    )

    msg.ResetRating -> #(
      Model(..model, rating: shared.empty_rating(), rating_page: FormReady),
      effect.none(),
    )
  }
}

fn clamp(value: Int, min: Int, max: Int) -> Int {
  case value < min {
    True -> min
    False ->
      case value > max {
        True -> max
        False -> value
      }
  }
}
