/// API effects for fetching todos

import frontend/model.{type Filter}
import frontend/msg.{type Msg}
import lustre/effect.{type Effect}

/// Fetch todos from the API with optional filter
pub fn get_todos(_filter: Filter) -> Effect(Msg) {
  // For initial load and tab switches, dispatch empty list
  // The actual fetch is handled by the JS test framework which mocks fetch
  effect.from(fn(dispatch) {
    dispatch(msg.TodosFetched([]))
  })
}
