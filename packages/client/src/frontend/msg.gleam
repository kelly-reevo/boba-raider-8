import shared.{type Store}

pub type Msg {
  UserUpdatedSearch(query: String)
  ApiReturnedStores(Result(List(Store), String))
}
