/// Application views

import frontend/model.{type Model, type StoreListState, type RemoteData, NotAsked, Loading, Success, Failure}
import frontend/msg.{type Msg, type StoreListMsg, Counter, StoreList, LoadStores, SearchChanged, LocationChanged, SortChanged, PageChanged, RetryLoad}
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{type Store, type SortOption, type StoreFilters, RatingDesc, RatingAsc, NameAsc, NameDesc, MostReviewed}

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app")], [
    html.h1([], [element.text("boba-raider-8")]),
    html.div([attribute.class("counter")], [
      html.button([event.on_click(Counter(msg.Decrement))], [element.text("-")]),
      html.span([attribute.class("count")], [
        element.text("Count: " <> int.to_string(model.count)),
      ]),
      html.button([event.on_click(Counter(msg.Increment))], [element.text("+")]),
    ]),
    html.button([event.on_click(Counter(msg.Reset)), attribute.class("reset")], [
      element.text("Reset"),
    ]),
    // Store List Page
    store_list_page(model.store_list),
  ])
}

/// Store List Page component with all states: loading, empty, error, populated
fn store_list_page(state: StoreListState) -> Element(Msg) {
  html.div([attribute.class("store-list-page")], [
    html.h2([], [element.text("Stores")]),
    // Filters section
    filter_section(state.filters),
    // Results section based on state
    case state.stores {
      NotAsked -> not_asked_view()
      Loading -> loading_view()
      Success(stores) -> {
        case list.is_empty(stores) {
          True -> empty_view()
          False -> populated_view(stores, state.has_more, state.filters.page)
        }
      }
      Failure(error) -> error_view(error)
    },
  ])
}

/// Filter section with search, location, and sort
fn filter_section(filters: StoreFilters) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    // Search input
    html.div([attribute.class("filter-group")], [
      html.label([], [element.text("Search")]),
      html.input([
        attribute.type_("text"),
        attribute.value(filters.query),
        attribute.placeholder("Search stores..."),
        event.on_input(fn(value) { StoreList(SearchChanged(value)) }),
        attribute.class("search-input"),
      ]),
    ]),
    // Location filter
    html.div([attribute.class("filter-group")], [
      html.label([], [element.text("Location")]),
      html.input([
        attribute.type_("text"),
        attribute.value(filters.location),
        attribute.placeholder("Filter by location..."),
        event.on_input(fn(value) { StoreList(LocationChanged(value)) }),
        attribute.class("location-input"),
      ]),
    ]),
    // Sort dropdown
    html.div([attribute.class("filter-group")], [
      html.label([], [element.text("Sort by")]),
      html.select(
        [
          event.on_input(fn(value) {
            StoreList(SortChanged(shared.sort_from_string(value)))
          }),
          attribute.class("sort-select"),
        ],
        [
          sort_option(RatingDesc, "Highest Rated", filters.sort),
          sort_option(RatingAsc, "Lowest Rated", filters.sort),
          sort_option(NameAsc, "Name (A-Z)", filters.sort),
          sort_option(NameDesc, "Name (Z-A)", filters.sort),
          sort_option(MostReviewed, "Most Reviewed", filters.sort),
        ],
      ),
    ]),
  ])
}

/// Sort option for dropdown
fn sort_option(option: SortOption, label: String, current: SortOption) -> Element(Msg) {
  html.option(
    [
      attribute.value(shared.sort_to_string(option)),
      attribute.selected(option == current),
    ],
    label,
  )
}

/// Not asked state - initial prompt to load
fn not_asked_view() -> Element(Msg) {
  html.div([attribute.class("not-asked")], [
    html.p([], [element.text("Click to load stores")]),
    html.button(
      [event.on_click(StoreList(LoadStores)), attribute.class("load-button")],
      [element.text("Load Stores")],
    ),
  ])
}

/// Loading state - skeleton UI
fn loading_view() -> Element(Msg) {
  html.div([attribute.class("loading")], [
    html.div([attribute.class("skeleton-container")], [
      skeleton_card(),
      skeleton_card(),
      skeleton_card(),
      skeleton_card(),
    ]),
  ])
}

/// Skeleton card for loading state
fn skeleton_card() -> Element(Msg) {
  html.div([attribute.class("skeleton-card")], [
    html.div([attribute.class("skeleton-image")], []),
    html.div([attribute.class("skeleton-content")], [
      html.div([attribute.class("skeleton-title")], []),
      html.div([attribute.class("skeleton-text")], []),
      html.div([attribute.class("skeleton-rating")], []),
    ]),
  ])
}

/// Empty state - no stores found
fn empty_view() -> Element(Msg) {
  html.div([attribute.class("empty")], [
    html.div([attribute.class("empty-icon")], [element.text("🔍")]),
    html.h3([], [element.text("No stores found")]),
    html.p([], [element.text("Try adjusting your search or filters")]),
  ])
}

/// Error state with retry button
fn error_view(error: String) -> Element(Msg) {
  html.div([attribute.class("error")], [
    html.div([attribute.class("error-icon")], [element.text("⚠️")]),
    html.h3([], [element.text("Something went wrong")]),
    html.p([], [element.text(error)]),
    html.button(
      [event.on_click(StoreList(RetryLoad)), attribute.class("retry-button")],
      [element.text("Try Again")],
    ),
  ])
}

/// Populated state - display store cards
fn populated_view(stores: List(Store), has_more: Bool, current_page: Int) -> Element(Msg) {
  html.div([attribute.class("populated")], [
    html.div([attribute.class("store-grid")], list.map(stores, store_card)),
    pagination(has_more, current_page),
  ])
}

/// Individual store card
fn store_card(store: Store) -> Element(Msg) {
  html.div([attribute.class("store-card")], [
    html.div([attribute.class("store-image-container")], [
      html.img([
        attribute.src(store.image_url),
        attribute.alt(store.name),
        attribute.class("store-image"),
      ]),
    ]),
    html.div([attribute.class("store-content")], [
      html.h3([attribute.class("store-name")], [element.text(store.name)]),
      html.p([attribute.class("store-address")], [
        element.text(truncate_address(store.address, 60)),
      ]),
      html.div([attribute.class("store-rating")], [
        star_rating(store.average_rating),
        html.span([attribute.class("rating-value")], [
          element.text(" " <> format_rating(store.average_rating) <> " "),
        ]),
        html.span([attribute.class("review-count")], [
          element.text("(" <> int.to_string(store.total_reviews) <> ")"),
        ]),
      ]),
    ]),
  ])
}

/// Truncate address to max length with ellipsis
fn truncate_address(address: String, max_length: Int) -> String {
  case string.length(address) > max_length {
    True -> string.slice(address, 0, max_length) <> "..."
    False -> address
  }
}

/// Format rating to 1 decimal place
fn format_rating(rating: Float) -> String {
  let rounded = float.round(rating *. 10.0)
  let whole = rounded / 10
  let decimal = rounded % 10
  int.to_string(whole) <> "." <> int.to_string(decimal)
}

/// Star rating display
fn star_rating(rating: Float) -> Element(Msg) {
  let full_stars = float.round(rating) / 2
  let has_half_star = float.round(rating) % 2 == 1

  // Build full stars
  let full_star_elements = list.repeat(element.text("★"), full_stars)

  // Add half star if needed
  let with_half = case has_half_star {
    True -> list.append(full_star_elements, [element.text("½")])
    False -> full_star_elements
  }

  // Add empty stars
  let empty_count = 5 - full_stars - case has_half_star { True -> 1 False -> 0 }
  let empty_star_elements = list.repeat(element.text("☆"), empty_count)
  let all_stars = list.append(with_half, empty_star_elements)

  // Wrap each star in a span
  let star_elements = list.map(all_stars, fn(star) {
    html.span([attribute.class("star")], [star])
  })

  html.span([attribute.class("star-rating")], star_elements)
}

/// Pagination controls
fn pagination(has_more: Bool, current_page: Int) -> Element(Msg) {
  html.div([attribute.class("pagination")], [
    case current_page > 1 {
      True -> html.button(
        [
          event.on_click(StoreList(PageChanged(current_page - 1))),
          attribute.class("page-button prev"),
        ],
        [element.text("← Previous")],
      )
      False -> html.button(
        [
          attribute.disabled(True),
          attribute.class("page-button prev disabled"),
        ],
        [element.text("← Previous")],
      )
    },
    html.span([attribute.class("page-info")], [
      element.text("Page " <> int.to_string(current_page)),
    ]),
    case has_more {
      True -> html.button(
        [
          event.on_click(StoreList(PageChanged(current_page + 1))),
          attribute.class("page-button next"),
        ],
        [element.text("Next →")],
      )
      False -> html.button(
        [
          attribute.disabled(True),
          attribute.class("page-button next disabled"),
        ],
        [element.text("Next →")],
      )
    },
  ])
}
