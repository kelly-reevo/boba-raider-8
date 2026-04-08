import gleam/option.{type Option, None}
import shared.{type FrontendDrink, type RatingSubmission, type RatingsSummary, type Store}

pub type LoadState {
  Loading
  Loaded
  Failed(String)
}

pub type Page {
  LoginPage
  RegisterPage
  ProfilePage
  StoreListPage
  StoreDetailPage(store_id: String)
  RatingPage
  RatingsDisplayPage
}

pub type AuthUser {
  AuthUser(id: String, username: String, email: String)
}

pub type RatingFormState {
  FormReady
  Submitting
  SubmitSuccess
  SubmitError(String)
}

pub type RatingsState {
  RatingsLoading
  RatingsLoaded(summary: RatingsSummary)
  RatingsError(message: String)
}

pub type Model {
  Model(
    page: Page,
    token: Option(String),
    user: Option(AuthUser),
    email: String,
    password: String,
    username: String,
    loading: Bool,
    error: String,
    stores: List(Store),
    search_query: String,
    store_load_state: LoadState,
    store: Option(Store),
    drinks: List(FrontendDrink),
    rating: RatingSubmission,
    rating_page: RatingFormState,
    ratings: RatingsState,
  )
}

pub fn default() -> Model {
  Model(
    page: LoginPage,
    token: None,
    user: None,
    email: "",
    password: "",
    username: "",
    loading: False,
    error: "",
    stores: [],
    search_query: "",
    store_load_state: Loading,
    store: None,
    drinks: [],
    rating: shared.empty_rating(),
    rating_page: FormReady,
    ratings: RatingsLoading,
  )
}
