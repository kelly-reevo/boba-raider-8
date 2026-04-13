/// Store List View - HTML rendering for the store list page

import frontend/store_list/model.{
  type Model, type Store, type LoadingState, Idle, Loading, Loaded, Error,
  has_next_page, has_prev_page, current_page, total_pages
}
import frontend/store_list/msg.{type Msg, SearchInputChanged, PageChanged, NextPage, PrevPage, DebouncedSearchTriggered}
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// Main view function
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("store-list-page")], [
    html.h1([], [element.text("Boba Stores")]),
    render_search_bar(model),
    render_store_grid(model),
    render_pagination(model),
  ])
}

/// Render search input bar
fn render_search_bar(model: Model) -> Element(Msg) {
  html.div([attribute.class("search-bar"), attribute.attribute("data-testid", "search-bar")], [
    html.input([
      attribute.type_("text"),
      attribute.placeholder("Search stores by name or city..."),
      attribute.value(model.search_term),
      attribute.attribute("data-testid", "search-input"),
      event.on_input(SearchInputChanged),
    ]),
  ])
}

/// Render the store grid or appropriate state message
fn render_store_grid(model: Model) -> Element(Msg) {
  case model.loading_state {
    Idle -> render_empty_state("Start searching to find boba stores")
    Loading -> render_loading_state()
    Error(msg) -> render_error_state(msg)
    Loaded -> {
      case model.stores {
        [] -> render_empty_state("No stores found matching your search")
        _ -> render_stores(model.stores)
      }
    }
  }
}

/// Render loading state
fn render_loading_state() -> Element(Msg) {
  html.div(
    [attribute.class("loading-state"), attribute.attribute("data-testid", "loading-state")],
    [element.text("Loading stores...")]
  )
}

/// Render error state
fn render_error_state(error_msg: String) -> Element(Msg) {
  html.div(
    [attribute.class("error-state"), attribute.attribute("data-testid", "error-state")],
    [
      html.h3([], [element.text("Error loading stores")]),
      html.p([], [element.text(error_msg)]),
    ]
  )
}

/// Render empty state
fn render_empty_state(message: String) -> Element(Msg) {
  html.div(
    [
      attribute.class("empty-state"),
      attribute.attribute("data-testid", "empty-state-message"),
    ],
    [element.text(message)]
  )
}

/// Render list of store cards
fn render_stores(stores: List(Store)) -> Element(Msg) {
  html.div(
    [attribute.class("store-grid"), attribute.attribute("data-testid", "store-grid")],
    list.map(stores, render_store_card)
  )
}

/// Render a single store card
fn render_store_card(store: Store) -> Element(Msg) {
  html.div(
    [
      attribute.class("store-card"),
      attribute.attribute("data-testid", "store-card"),
    ],
    [
      html.a([attribute.href("/stores/" <> store.id)], [
        html.h3(
          [attribute.attribute("data-testid", "store-name")],
          [element.text(store.name)]
        ),
        html.p(
          [attribute.attribute("data-testid", "store-city")],
          [element.text(store.city)]
        ),
        html.span(
          [
            attribute.class("drink-count"),
            attribute.attribute("data-testid", "drink-count"),
          ],
          [element.text(int.to_string(store.drink_count))]
        ),
      ]),
    ]
  )
}

/// Render pagination controls
fn render_pagination(model: Model) -> Element(Msg) {
  // Only show pagination if there are stores and more than one page
  let total = total_pages(model.pagination)
  let current = current_page(model.pagination)

  case model.stores, total {
    [], _ -> element.text("")
    _, 1 -> element.text("")
    _, _ -> {
      html.div(
        [
          attribute.class("pagination-controls"),
          attribute.attribute("data-testid", "pagination-controls"),
        ],
        [
          render_prev_button(has_prev_page(model.pagination)),
          html.div([attribute.class("page-numbers")], render_page_numbers(total, current)),
          render_next_button(has_next_page(model.pagination)),
        ]
      )
    }
  }
}

/// Render previous page button
fn render_prev_button(enabled: Bool) -> Element(Msg) {
  case enabled {
    True -> {
      html.button(
        [
          attribute.class("prev-page"),
          attribute.attribute("data-testid", "prev-page"),
          event.on_click(PrevPage),
        ],
        [element.text("Previous")]
      )
    }
    False -> {
      html.button(
        [
          attribute.class("prev-page disabled"),
          attribute.attribute("data-testid", "prev-page"),
          attribute.attribute("disabled", "true"),
          attribute.attribute("aria-disabled", "true"),
        ],
        [element.text("Previous")]
      )
    }
  }
}

/// Render next page button
fn render_next_button(enabled: Bool) -> Element(Msg) {
  case enabled {
    True -> {
      html.button(
        [
          attribute.class("next-page"),
          attribute.attribute("data-testid", "next-page"),
          event.on_click(NextPage),
        ],
        [element.text("Next")]
      )
    }
    False -> {
      html.button(
        [
          attribute.class("next-page disabled"),
          attribute.attribute("data-testid", "next-page"),
          attribute.attribute("disabled", "true"),
          attribute.attribute("aria-disabled", "true"),
        ],
        [element.text("Next")]
      )
    }
  }
}

/// Render page number buttons
fn render_page_numbers(total: Int, current: Int) -> List(Element(Msg)) {
  // Generate page numbers using recursive function
  render_page_numbers_recursive(total, current, 1, [])
}

fn render_page_numbers_recursive(
  total: Int,
  current: Int,
  page: Int,
  acc: List(Element(Msg)),
) -> List(Element(Msg)) {
  case page > total {
    True -> list.reverse(acc)
    False -> {
      let is_current = page == current
      let classes = case is_current {
        True -> "page-number current"
        False -> "page-number"
      }

      let button = html.button(
        [
          attribute.class(classes),
          attribute.attribute("data-testid", "page-number"),
          case is_current {
            True -> attribute.attribute("disabled", "true")
            False -> event.on_click(PageChanged(page))
          },
        ],
        [element.text(int.to_string(page))]
      )

      render_page_numbers_recursive(total, current, page + 1, [button, ..acc])
    }
  }
}
