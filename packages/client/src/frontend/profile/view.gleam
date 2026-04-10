import frontend/profile/model.{type Model}
import frontend/profile/msg.{type Msg}
import gleam/float
import gleam/int
import gleam/list
import shared.{
  type DrinkRating, type LoadState, type ProfileTab, type StoreRating,
  type UserProfile, DrinkRatingsTab, Empty, Error, Loading, Populated,
  StoreRatingsTab,
}
import lustre/attribute
import lustre/element.{type Element, fragment as element_fragment, text as element_text}
import lustre/element/html
import lustre/event

/// Main profile page view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("profile-page")], [
    // Header section with user info and stats
    view_profile_header(model.profile),
    // Tab navigation
    view_tab_navigation(model.active_tab),
    // Tab content area
    view_tab_content(model),
  ])
}

// Header Section

fn view_profile_header(profile_state: LoadState(UserProfile)) -> Element(Msg) {
  case profile_state {
    Loading -> view_header_loading()
    Error(error) -> view_header_error(error)
    Empty -> view_header_empty()
    Populated(profile) -> view_header_populated(profile)
  }
}

fn view_header_loading() -> Element(Msg) {
  html.div([attribute.class("profile-header profile-header--loading")], [
    html.div([attribute.class("profile-avatar profile-avatar--skeleton")], []),
    html.div([attribute.class("profile-info")], [
      html.div([attribute.class("skeleton-text skeleton-text--large")], []),
      html.div([attribute.class("skeleton-text skeleton-text--small")], []),
    ]),
    html.div([attribute.class("profile-stats profile-stats--skeleton")], [
      html.div([attribute.class("skeleton-stat")], []),
      html.div([attribute.class("skeleton-stat")], []),
      html.div([attribute.class("skeleton-stat")], []),
      html.div([attribute.class("skeleton-stat")], []),
    ]),
  ])
}

fn view_header_error(error: String) -> Element(Msg) {
  html.div([attribute.class("profile-header profile-header--error")], [
    html.div([attribute.class("profile-error")], [
      html.span([attribute.class("error-icon")], [element_text("⚠️")]),
      html.p([], [element_text("Failed to load profile: " <> error)]),
      html.button(
        [event.on_click(msg.LoadProfile), attribute.class("retry-btn")],
        [element_text("Retry")],
      ),
    ]),
  ])
}

fn view_header_empty() -> Element(Msg) {
  html.div([attribute.class("profile-header profile-header--empty")], [
    html.p([], [element_text("No profile data available.")]),
  ])
}

fn view_header_populated(profile: UserProfile) -> Element(Msg) {
  html.div([attribute.class("profile-header")], [
    html.div([attribute.class("profile-avatar-section")], [
      html.img([
        attribute.src(profile.user.avatar_url),
        attribute.alt("Profile avatar"),
        attribute.class("profile-avatar"),
      ]),
      html.h1([attribute.class("profile-username")], [
        element_text(profile.user.username),
      ]),
      html.p([attribute.class("profile-email")], [
        element_text(profile.user.email),
      ]),
    ]),
    html.div([attribute.class("profile-stats")], [
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          element_text(int.to_string(profile.stats.total_store_ratings)),
        ]),
        html.span([attribute.class("stat-label")], [
          element_text("Store Ratings"),
        ]),
      ]),
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          element_text(int.to_string(profile.stats.total_drink_ratings)),
        ]),
        html.span([attribute.class("stat-label")], [
          element_text("Drink Ratings"),
        ]),
      ]),
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          element_text(format_rating(profile.stats.average_store_rating)),
        ]),
        html.span([attribute.class("stat-label")], [
          element_text("Avg Store Rating"),
        ]),
      ]),
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          element_text(format_rating(profile.stats.average_drink_rating)),
        ]),
        html.span([attribute.class("stat-label")], [
          element_text("Avg Drink Rating"),
        ]),
      ]),
    ]),
  ])
}

// Tab Navigation

fn view_tab_navigation(active_tab: ProfileTab) -> Element(Msg) {
  html.div([attribute.class("tab-navigation")], [
    html.button(
      [
        attribute.class(case active_tab {
          StoreRatingsTab -> "tab-btn tab-btn--active"
          DrinkRatingsTab -> "tab-btn"
        }),
        event.on_click(msg.SwitchTab(StoreRatingsTab)),
      ],
      [element_text("My Store Ratings")],
    ),
    html.button(
      [
        attribute.class(case active_tab {
          StoreRatingsTab -> "tab-btn"
          DrinkRatingsTab -> "tab-btn tab-btn--active"
        }),
        event.on_click(msg.SwitchTab(DrinkRatingsTab)),
      ],
      [element_text("My Drink Ratings")],
    ),
  ])
}

// Tab Content

fn view_tab_content(model: Model) -> Element(Msg) {
  case model.active_tab {
    StoreRatingsTab -> view_store_ratings_tab(model)
    DrinkRatingsTab -> view_drink_ratings_tab(model)
  }
}

// Store Ratings Tab

fn view_store_ratings_tab(model: Model) -> Element(Msg) {
  html.div([attribute.class("tab-content")], [
    case model.store_ratings {
      Loading -> view_list_loading()
      Error(error) -> view_list_error(error, msg.LoadStoreRatings(model.current_page))
      Empty -> view_list_empty("You haven't rated any stores yet.")
      Populated(ratings) -> view_store_ratings_list(model, ratings)
    },
  ])
}

fn view_store_ratings_list(
  model: Model,
  ratings: List(StoreRating),
) -> Element(Msg) {
  html.div([attribute.class("ratings-list")], [
    html.div([attribute.class("ratings-items")], [
      list.map(ratings, view_store_rating_item)
      |> element_fragment(),
    ]),
    view_pagination(
      model.current_page,
      model.per_page,
      model.store_ratings_total,
    ),
  ])
}

fn view_store_rating_item(rating: StoreRating) -> Element(Msg) {
  html.div([attribute.class("rating-item rating-item--store")], [
    html.div([attribute.class("rating-header")], [
      html.h3([attribute.class("rating-title")], [
        element_text(rating.store_name),
      ]),
      html.div([attribute.class("rating-stars")], [
        view_star_rating(rating.rating),
      ]),
    ]),
    html.p([attribute.class("rating-review")], [element_text(rating.review)]),
    html.span([attribute.class("rating-date")], [
      element_text("Rated on " <> rating.created_at),
    ]),
  ])
}

// Drink Ratings Tab

fn view_drink_ratings_tab(model: Model) -> Element(Msg) {
  html.div([attribute.class("tab-content")], [
    case model.drink_ratings {
      Loading -> view_list_loading()
      Error(error) -> view_list_error(error, msg.LoadDrinkRatings(model.current_page))
      Empty -> view_list_empty("You haven't rated any drinks yet.")
      Populated(ratings) -> view_drink_ratings_list(model, ratings)
    },
  ])
}

fn view_drink_ratings_list(
  model: Model,
  ratings: List(DrinkRating),
) -> Element(Msg) {
  html.div([attribute.class("ratings-list")], [
    html.div([attribute.class("ratings-items")], [
      list.map(ratings, view_drink_rating_item)
      |> element_fragment(),
    ]),
    view_pagination(
      model.current_page,
      model.per_page,
      model.drink_ratings_total,
    ),
  ])
}

fn view_drink_rating_item(rating: DrinkRating) -> Element(Msg) {
  html.div([attribute.class("rating-item rating-item--drink")], [
    html.div([attribute.class("rating-header")], [
      html.h3([attribute.class("rating-title")], [
        element_text(rating.drink_name),
      ]),
      html.div([attribute.class("rating-stars")], [
        view_star_rating(rating.rating),
      ]),
    ]),
    html.p([attribute.class("rating-store")], [
      element_text("From: " <> rating.store_name),
    ]),
    html.p([attribute.class("rating-review")], [element_text(rating.review)]),
    html.span([attribute.class("rating-date")], [
      element_text("Rated on " <> rating.created_at),
    ]),
  ])
}

// Shared List States

fn view_list_loading() -> Element(Msg) {
  html.div([attribute.class("ratings-list ratings-list--loading")], [
    html.div([attribute.class("skeleton-item")], []),
    html.div([attribute.class("skeleton-item")], []),
    html.div([attribute.class("skeleton-item")], []),
  ])
}

fn view_list_error(error: String, retry_msg: Msg) -> Element(Msg) {
  html.div([attribute.class("ratings-list ratings-list--error")], [
    html.div([attribute.class("list-error")], [
      html.span([attribute.class("error-icon")], [element_text("⚠️")]),
      html.p([], [element_text("Failed to load ratings: " <> error)]),
      html.button(
        [event.on_click(retry_msg), attribute.class("retry-btn")],
        [element_text("Retry")],
      ),
    ]),
  ])
}

fn view_list_empty(message: String) -> Element(Msg) {
  html.div([attribute.class("ratings-list ratings-list--empty")], [
    html.div([attribute.class("empty-state")], [
      html.span([attribute.class("empty-icon")], [element_text("📝")]),
      html.p([], [element_text(message)]),
    ]),
  ])
}

// Pagination

fn view_pagination(
  current_page: Int,
  per_page: Int,
  total_items: Int,
) -> Element(Msg) {
  let total_pages = case total_items % per_page {
    0 -> total_items / per_page
    _ -> total_items / per_page + 1
  }

  case total_pages <= 1 {
    True -> element_text("")
    False -> {
      html.div([attribute.class("pagination")], [
        html.button(
          [
            attribute.class("pagination-btn pagination-btn--prev"),
            attribute.disabled(current_page <= 1),
            event.on_click(msg.ChangePage(current_page - 1)),
          ],
          [element_text("Previous")],
        ),
        html.span([attribute.class("pagination-info")], [
          element_text(
            "Page " <> int.to_string(current_page) <> " of " <> int.to_string(total_pages),
          ),
        ]),
        html.button(
          [
            attribute.class("pagination-btn pagination-btn--next"),
            attribute.disabled(current_page >= total_pages),
            event.on_click(msg.ChangePage(current_page + 1)),
          ],
          [element_text("Next")],
        ),
      ])
    }
  }
}

// Utilities

fn view_star_rating(rating: Int) -> Element(Msg) {
  let stars = list.range(1, 5)
  html.span([attribute.class("stars")], [
    list.map(stars, fn(star) {
      let star_class = case star <= rating {
        True -> "star star--filled"
        False -> "star star--empty"
      }
      html.span([attribute.class(star_class)], [element_text("★")])
    })
    |> element_fragment(),
  ])
}

fn format_rating(rating: Float) -> String {
  let rounded = float.round(rating *. 10.0)
  let whole = rounded / 10
  let decimal = rounded % 10
  int.to_string(whole) <> "." <> int.to_string(decimal)
}
