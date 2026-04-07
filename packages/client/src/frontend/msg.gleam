/// Application messages

import frontend/model
import shared

pub type Msg {
  OnRouteChange(model.Page)
  GotStore(Result(shared.Store, String))
  GotDrinks(Result(List(shared.Drink), String))
}
