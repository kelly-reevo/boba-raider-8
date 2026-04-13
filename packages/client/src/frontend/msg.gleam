/// Application messages

import shared.{type Todo}

pub type Msg {
  FilterChanged(String)
  TodosFetched(List(Todo))
  FetchError(String)
}
