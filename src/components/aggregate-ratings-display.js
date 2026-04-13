/**
 * Aggregate Ratings Display Component
 *
 * Displays calculated average ratings across all four axes with visual charts/bars.
 * Handles loading, empty, error, and populated states.
 */

/**
 * Aggregates data structure from API
 * @typedef {Object} Aggregates
 * @property {number|null} overall_rating - Average overall rating (0-5 scale)
 * @property {number|null} sweetness - Average sweetness rating (0-10 scale)
 * @property {number|null} boba_texture - Average boba texture rating (0-10 scale)
 * @property {number|null} tea_strength - Average tea strength rating (0-10 scale)
 * @property {number} count - Number of ratings
 */

/**
 * Renders star rating display based on numeric rating
 * @param {number} rating - Rating value (0-5)
 * @returns {string} HTML string for stars
 */
function renderStars(rating) {
  return `<span class="stars" data-rating="${rating}"></span>`;
}

/**
 * Formats a rating value for display
 * @param {number|null} value - Rating value
 * @returns {string} Formatted value (e.g., "4.2" or "-")
 */
function formatRatingValue(value) {
  if (value === null || value === undefined) {
    return '-';
  }
  return value.toFixed(1);
}

/**
 * Calculates bar width percentage for axis ratings (1-10 scale)
 * @param {number|null} value - Axis rating value
 * @returns {number} Percentage (0-100)
 */
function calculateBarWidth(value) {
  if (value === null || value === undefined) {
    return 0;
  }
  return value * 10;
}

/**
 * Renders a single axis bar chart
 * @param {string} axis - Axis name (sweetness, boba_texture, tea_strength)
 * @param {string} label - Display label
 * @param {number|null} value - Axis rating value
 * @returns {string} HTML string for axis bar
 */
function renderAxisBar(axis, label, value) {
  const width = calculateBarWidth(value);
  const displayValue = formatRatingValue(value);

  return `
    <div class="axis-bar" data-axis="${axis}">
      <span class="axis-label">${label}</span>
      <div class="bar-container">
        <div class="bar-fill" style="width: ${width}%"></div>
      </div>
      <span class="axis-value">${displayValue}</span>
    </div>
  `;
}

/**
 * Renders the axis breakdown section with all three axes
 * @param {Aggregates} aggregates - Rating aggregates
 * @returns {string} HTML string for axis breakdown
 */
function renderAxisBreakdown(aggregates) {
  return `
    <div class="axis-breakdown">
      ${renderAxisBar('sweetness', 'Sweetness', aggregates.sweetness)}
      ${renderAxisBar('boba_texture', 'Boba Texture', aggregates.boba_texture)}
      ${renderAxisBar('tea_strength', 'Tea Strength', aggregates.tea_strength)}
    </div>
  `;
}

/**
 * Renders the ratings count text with proper pluralization
 * @param {number} count - Number of ratings
 * @returns {string} HTML string for ratings count
 */
function renderRatingsCount(count) {
  const pluralSuffix = count === 1 ? '' : 's';
  return `<div class="ratings-count">Based on ${count} rating${pluralSuffix}</div>`;
}

/**
 * Renders the empty state when no ratings exist
 * @returns {string} HTML string for empty state
 */
function renderEmptyState() {
  return `
    <div class="no-ratings">
      <p class="empty-message">No ratings yet - be the first!</p>
      <button class="cta-button" data-action="submit-rating">Submit a Rating</button>
    </div>
  `;
}

/**
 * Renders the overall rating section
 * @param {number|null} overallRating - Overall rating value (0-5 scale)
 * @returns {string} HTML string for overall rating
 */
function renderOverallRating(overallRating) {
  const displayValue = formatRatingValue(overallRating);
  const starRating = overallRating !== null ? overallRating : 0;

  return `
    <div class="overall-rating">
      ${renderStars(starRating)}
      <span class="rating-value">${displayValue}</span>
      <span class="rating-max">/5</span>
    </div>
  `;
}

/**
 * Renders the complete aggregate ratings display
 * @param {Aggregates} aggregates - Rating aggregates data
 * @returns {string} Complete HTML string for the component
 */
export function renderAggregateRatings(aggregates) {
  const isEmpty = aggregates.count === 0;

  if (isEmpty) {
    return `
      <div class="aggregate-ratings empty-state">
        ${renderOverallRating(null)}
        ${renderEmptyState()}
      </div>
    `;
  }

  return `
    <div class="aggregate-ratings">
      ${renderOverallRating(aggregates.overall_rating)}
      ${renderAxisBreakdown(aggregates)}
      ${renderRatingsCount(aggregates.count)}
    </div>
  `;
}

/**
 * Mounts the aggregate ratings display to a DOM container
 * @param {HTMLElement} container - DOM element to mount to
 * @param {Aggregates} aggregates - Rating aggregates data
 */
export function mountAggregateRatings(container, aggregates) {
  container.innerHTML = renderAggregateRatings(aggregates);
}

/**
 * Creates a new aggregate ratings display element
 * @param {Aggregates} aggregates - Rating aggregates data
 * @returns {HTMLDivElement} The created component element
 */
export function createAggregateRatingsElement(aggregates) {
  const wrapper = document.createElement('div');
  wrapper.id = 'ratings-display';
  wrapper.innerHTML = renderAggregateRatings(aggregates);
  return wrapper;
}

/**
 * Fetches aggregate ratings from API and renders to container
 * @param {string} drinkId - Drink ID to fetch ratings for
 * @param {HTMLElement} container - DOM element to render into
 * @throws {Error} When fetch fails or response is invalid
 */
export async function fetchAndRenderAggregateRatings(drinkId, container) {
  const response = await fetch(`/api/drinks/${drinkId}/ratings/aggregate`);

  if (!response.ok) {
    throw new Error(`Failed to fetch aggregate ratings: ${response.status}`);
  }

  const data = await response.json();

  // Handle API response format (total_count -> count mapping)
  const aggregates = {
    overall_rating: data.overall_rating ?? null,
    sweetness: data.sweetness ?? null,
    boba_texture: data.boba_texture ?? null,
    tea_strength: data.tea_strength ?? null,
    count: data.count ?? data.total_count ?? 0
  };

  mountAggregateRatings(container, aggregates);
}

/**
 * Renders loading state
 * @returns {string} HTML string for loading state
 */
export function renderLoadingState() {
  return `
    <div class="aggregate-ratings loading-state">
      <div class="loading-message">Loading ratings...</div>
    </div>
  `;
}

/**
 * Renders error state
 * @param {string} message - Error message to display
 * @returns {string} HTML string for error state
 */
export function renderErrorState(message) {
  return `
    <div class="aggregate-ratings error-state">
      <div class="error-message">${message}</div>
      <button class="retry-button" data-action="retry">Retry</button>
    </div>
  `;
}
