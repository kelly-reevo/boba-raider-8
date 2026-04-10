/// Application messages

/// Form display mode for rating form
pub type DisplayMode {
  Modal
  Inline
}

/// Rating form messages
pub type Msg {
  // Counter messages (existing)
  Increment
  Decrement
  Reset

  // Store rating form messages
  /// Open rating form for a store (new rating)
  RatingFormOpened(store_id: String, display_mode: DisplayMode)

  /// Open rating form with existing rating data for editing
  RatingFormOpenedForEdit(
    store_id: String,
    rating_id: String,
    overall_score: Int,
    review_text: String,
    display_mode: DisplayMode,
  )

  /// Close the rating form modal
  RatingFormClosed

  /// Star score selection changed
  RatingScoreChanged(score: Int)

  /// Review text input changed
  RatingReviewTextChanged(text: String)

  /// Form submitted
  RatingFormSubmitted

  /// Delete rating button clicked
  RatingDeleteClicked

  /// Rating created successfully
  RatingCreated(store_id: String)

  /// Rating updated successfully
  RatingUpdated(store_id: String)

  /// Rating deleted successfully
  RatingDeleted(store_id: String)

  /// Rating API error
  RatingApiError(error: String)
}
