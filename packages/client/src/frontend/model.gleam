/// Application state

pub type Model {
  Model(count: Int, error: String)
}

pub fn default() -> Model {
  Model(count: 0, error: "")
}
