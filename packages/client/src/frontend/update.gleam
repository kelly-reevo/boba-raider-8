import frontend/effects
import frontend/model.{
  type Model, Failed, Loaded, LoginPage, Model, ProfilePage, RegisterPage,
  StoreDetailPage, StoreListPage,
}
import frontend/msg.{type Msg}
import gleam/option.{None, Some}
import lustre/effect.{type Effect}

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
  }
}
