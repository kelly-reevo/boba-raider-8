import frontend/model.{type Model, CreateStorePage, HomePage}
import frontend/msg.{type Msg, CreateStoreMsg, NavigateToCreateStore}
import frontend/pages/create_store_page
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared.{error_message}

/// Main application view
pub fn view(model: Model) -> Element(Msg) {
  case model.current_page {
    Home -> view_home()
    StoreDetail(store_id) -> {
      let store_model = init_store_detail(store_id, model.auth)
      view_store_detail_page(store_model)
    }
  }
}

/// Helper to create a StoreDetailModel (mirrors model.init_store_detail)
fn init_store_detail(store_id: String, auth: AuthState) -> StoreDetailModel {
  StoreDetailModel(
    store_id: store_id,
    data: Loading,
    auth: auth,
  )
}

fn view_home() -> Element(Msg) {
  html.div([attribute.class("app")], [
    view_navigation(),
    view_page_content(model)
  ])
}

/// Navigation header
fn view_navigation() -> Element(Msg) {
  html.nav([attribute.class("main-nav")], [
    html.a([attribute.href("/"), attribute.class("logo")], [
      element.text("boba-raider-8")
    ]),
    html.div([attribute.class("nav-links")], [
      html.a([attribute.href("/"), attribute.class("nav-link")], [
        element.text("Home")
      ]),
      html.button(
        [
          attribute.class("nav-link btn-link"),
          event.on_click(NavigateToCreateStore)
        ],
        [element.text("Create Store")]
      )
    ])
  ])
}

/// Route to correct page view
fn view_page_content(model: Model) -> Element(Msg) {
  case model.current_page {
    HomePage -> view_home()
    CreateStorePage(state) -> {
      // Map page view to global Msg type
      element.map(create_store_page.view(state), fn(m) { CreateStoreMsg(m) })
    }
  }
}

/// Home page view
fn view_home() -> Element(Msg) {
  html.div([attribute.class("home-page")], [
    html.h1([], [element.text("Welcome to boba-raider-8")]),
    html.p([], [
      element.text("Click 'Create Store' to add a new store listing.")
    ])
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

/// Render the appropriate page based on current route
fn render_route(model: Model) -> Element(Msg) {
  case model.route {
    route if route == Home -> home_page(model)
    route if route == Login -> login_page(model)
    route if route == Register -> register_page(model)
    _ -> home_page(model)
  }
}

/// Navigation bar with auth-aware links
fn navigation_bar(model: Model) -> Element(Msg) {
  html.nav([attribute.class("navbar")], [
    html.div([attribute.class("nav-brand")], [
      html.a(
        [attribute.href("#/"), event.on_click(NavigateTo(Home))],
        [element.text("BobaRaider")],
      ),
    ]),
    html.div([attribute.class("nav-links")], [
      case model.auth {
        LoggedIn(user, _) -> {
          // Logged in: show user name and logout
          html.div([attribute.class("auth-section")], [
            html.span([attribute.class("user-name")], [
              element.text(user.username),
            ]),
            html.button(
              [
                attribute.class("btn btn-secondary"),
                event.on_click(LogoutRequested),
              ],
              [element.text("Logout")],
            ),
          ])
        }
        _ -> {
          // Not logged in: show login/register links
          html.div([attribute.class("auth-section")], [
            html.a(
              [
                attribute.href("#/login"),
                event.on_click(NavigateTo(Login)),
                attribute.class("nav-link"),
              ],
              [element.text("Sign In")],
            ),
            html.a(
              [
                attribute.href("#/register"),
                event.on_click(NavigateTo(Register)),
                attribute.class("nav-link btn btn-primary"),
              ],
              [element.text("Sign Up")],
            ),
          ])
        }
      },
    ]),
  ])
}

/// Home page component
fn home_page(model: Model) -> Element(Msg) {
  html.div([attribute.class("home-page")], [
    case model.auth {
      LoggedIn(user, _) -> {
        // Authenticated home
        html.div([attribute.class("welcome-section")], [
          html.h1([], [element.text("Welcome back, " <> user.username <> "!")]),
          html.p([], [
            element.text("You are successfully authenticated. Your session is stored in localStorage."),
          ]),
          html.div([attribute.class("user-card")], [
            html.h3([], [element.text("Your Profile")]),
            html.p([], [element.text("ID: " <> user.id)]),
            html.p([], [element.text("Email: " <> user.email)]),
            html.p([], [element.text("Username: " <> user.username)]),
          ]),
        ])
      }
      _ -> {
        // Unauthenticated home
        html.div([attribute.class("welcome-section")], [
          html.h1([], [element.text("Welcome to BobaRaider")]),
          html.p([], [
            element.text("Please sign in or create an account to continue."),
          ]),
          html.div([attribute.class("cta-buttons")], [
            html.a(
              [
                attribute.href("#/login"),
                event.on_click(NavigateTo(Login)),
                attribute.class("btn btn-primary"),
              ],
              [element.text("Sign In")],
            ),
            html.a(
              [
                attribute.href("#/register"),
                event.on_click(NavigateTo(Register)),
                attribute.class("btn btn-secondary"),
              ],
              [element.text("Create Account")],
            ),
          ]),
        ])
      }
    },
  ])
}

/// Map location section
fn view_map_location(store: Store) -> Element(Msg) {
  html.div([attribute.class("map-section")], [
    html.h2([], [element.text("Location")]),
    html.div(
      [
        attribute.class("map-container"),
        // Data attributes for map initialization
        attribute.attribute("data-lat", float.to_string(store.latitude)),
        attribute.attribute("data-lng", float.to_string(store.longitude)),
        attribute.attribute("data-name", store.name),
      ],
      [
        // Static map placeholder - in production this would integrate with a map library
        html.div([attribute.class("map-placeholder")], [
          element.text("📍 " <> store.name),
          html.br([]),
          element.text(
            "Coordinates: "
            <> float.to_string(store.latitude)
            <> ", "
            <> float.to_string(store.longitude),
          ),
        ]),
      ],
    ),
  ])
}

/// Add drink button (only shown for authenticated users)
fn view_add_drink_button(auth: AuthState) -> Element(Msg) {
  case auth {
    Authenticated(_, _) -> {
      html.div([attribute.class("add-drink-section")], [
        html.button(
          [
            attribute.class("add-drink-button"),
            event.on_click(wrap(ClickedAddDrink)),
          ],
          [element.text("+ Add Drink")],
        ),
      ])
    }
    Anonymous -> {
      // Empty element for anonymous users
      element.none()
    }
  }
}

/// Drinks list section
fn view_drinks_section(drinks: List(Drink)) -> Element(Msg) {
  html.div([attribute.class("drinks-section")], [
    html.h2([], [element.text("Drinks")]),
    case drinks {
      [] -> html.p([attribute.class("empty-state")], [element.text("No drinks listed yet.")])
      _ -> html.div([attribute.class("drinks-list")], list.map(drinks, view_drink_card))
    },
  ])
}

/// Single drink card
fn view_drink_card(drink: Drink) -> Element(Msg) {
  html.div([attribute.class("drink-card")], [
    html.div([attribute.class("drink-image")], [
      html.img([
        attribute.src(drink.image_url),
        attribute.alt(drink.name),
      ]),
    ]),
    html.div([attribute.class("drink-info")], [
      html.h3([attribute.class("drink-name")], [element.text(drink.name)]),
      html.p([attribute.class("drink-category")], [element.text(drink.category)]),
      html.p([attribute.class("drink-description")], [element.text(drink.description)]),
      html.div([attribute.class("drink-price")], [
        element.text(drink.currency <> format_price(drink.price)),
      ]),
    ]),
  ])
}

fn format_price(price: Float) -> String {
  // Format to 2 decimal places
  let whole = float.truncate(price)
  let decimal = float.truncate({price -. int.to_float(whole)} *. 100.0)
  int.to_string(whole) <> "." <> case decimal {
    d if d < 10 -> "0" <> int.to_string(d)
    d -> int.to_string(d)
  }
}

/// Ratings section
fn view_ratings_section(ratings: List(Rating)) -> Element(Msg) {
  html.div([attribute.class("ratings-section")], [
    html.h2([], [element.text("Reviews")]),
    case ratings {
      [] -> html.p([attribute.class("empty-state")], [element.text("No reviews yet. Be the first to review!")])
      _ -> html.div([attribute.class("ratings-list")], list.map(ratings, view_rating_card))
    },
  ])
}

/// Single rating card
fn view_rating_card(rating: Rating) -> Element(Msg) {
  html.div([attribute.class("rating-card")], [
    html.div([attribute.class("rating-header")], [
      html.span([attribute.class("rating-username")], [element.text(rating.username)]),
      html.span([attribute.class("rating-date")], [element.text(rating.created_at)]),
    ]),
    html.div([attribute.class("rating-stars")], [
      element.text(render_stars(rating.rating)),
    ]),
    html.p([attribute.class("rating-review")], [element.text(rating.review)]),
  ])
}

fn render_stars(rating: Int) -> String {
  case rating {
    5 -> "★★★★★"
    4 -> "★★★★☆"
    3 -> "★★★☆☆"
    2 -> "★★☆☆☆"
    1 -> "★☆☆☆☆"
    0 -> "☆☆☆☆☆"
    _ -> "★★★★★"
  }
}
