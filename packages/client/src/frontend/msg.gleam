pub type HttpError {
  NetworkError
  DecodeError
  ServerError(Int)
}

pub type Msg {
  Increment
  Decrement
  Reset
  GotCounter(Result(Int, HttpError))
}
