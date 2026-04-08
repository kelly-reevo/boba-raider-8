import frontend/model.{type AuthUser}
import shared.{type FrontendDrink, type Store}

pub type AuthResult {
  AuthResult(token: String, user: AuthUser)
}

pub type Msg {
  // Navigation
  GoToLogin
  GoToRegister
  GoToProfile
  GoToStoreList
  GoToStoreDetail(store_id: String)
  // Form inputs
  SetEmail(String)
  SetPassword(String)
  SetUsername(String)
  // Auth actions
  SubmitLogin
  SubmitRegister
  Logout
  // Auth API responses
  GotAuth(Result(AuthResult, String))
  GotProfile(Result(AuthUser, String))
  // Init: restore session from localStorage
  GotSavedToken(String)
  // Store listing
  UserUpdatedSearch(query: String)
  ApiReturnedStores(Result(List(Store), String))
  // Store detail
  GotStore(Result(Store, String))
  GotDrinks(Result(List(FrontendDrink), String))
}
