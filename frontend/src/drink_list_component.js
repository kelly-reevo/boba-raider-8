/**
 * Drink List Component
 * Renders a list of drinks with key info and ratings preview
 * Boundary: Input Drink[] -> Renders clickable cards linking to /drinks/:id
 */

/**
 * Escapes HTML to prevent XSS attacks
 * @param {string} text - Raw text to escape
 * @returns {string} Escaped HTML string
 */
function escapeHtml(text) {
  if (text === null || text === undefined) {
    return '';
  }
  const div = document.createElement('div');
  div.textContent = String(text);
  return div.innerHTML;
}

/**
 * Formats price to 2 decimal places with $ prefix
 * @param {number} price - Price value
 * @returns {string} Formatted price string
 */
function formatPrice(price) {
  if (price === null || price === undefined) {
    return null;
  }
  const num = Number(price);
  if (Number.isNaN(num)) {
    return null;
  }
  return `$${num.toFixed(2)}`;
}

/**
 * Renders star rating HTML
 * @param {number} rating - Rating value (0-5)
 * @returns {string} HTML string for star rating
 */
function renderStars(rating) {
  const fullStars = Math.floor(rating);
  const hasHalfStar = rating % 1 >= 0.5;
  const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

  let starsHtml = '';

  // Full stars
  for (let i = 0; i < fullStars; i++) {
    starsHtml += '<span class="star full">★</span>';
  }

  // Half star
  if (hasHalfStar) {
    starsHtml += '<span class="star half">★</span>';
  }

  // Empty stars
  for (let i = 0; i < emptyStars; i++) {
    starsHtml += '<span class="star empty">☆</span>';
  }

  return starsHtml;
}

/**
 * Renders the rating section for a drink
 * @param {Object} aggregates - Rating aggregates object
 * @returns {string} HTML string for rating section
 */
function renderRating(aggregates) {
  // Handle null/undefined aggregates or missing count/overall_rating
  if (!aggregates || typeof aggregates !== 'object') {
    return '<span class="rating-not-rated">Not rated yet</span>';
  }

  const count = aggregates.count;
  const rating = aggregates.overall_rating;

  // Show "Not rated yet" if count is 0, null, undefined, or if rating is missing
  if (count === null || count === undefined || count === 0 || rating === null || rating === undefined) {
    return '<span class="rating-not-rated">Not rated yet</span>';
  }

  const ratingNum = Number(rating);
  if (Number.isNaN(ratingNum)) {
    return '<span class="rating-not-rated">Not rated yet</span>';
  }

  // Clamp rating to 0-5 range
  const clampedRating = Math.max(0, Math.min(5, ratingNum));

  const ratingWord = count === 1 ? 'rating' : 'ratings';

  return `
    <span class="star-rating" aria-label="Rating: ${Math.round(clampedRating)} out of 5">
      ${renderStars(clampedRating)}
    </span>
    <span class="rating-count">(${count} ${ratingWord})</span>
  `;
}

/**
 * Renders a single drink card
 * @param {Object} drink - Drink object
 * @returns {string} HTML string for drink card
 */
function renderDrinkCard(drink) {
  const id = escapeHtml(drink.id);
  const name = escapeHtml(drink.name);

  // Handle tea type - show "unknown" if missing or empty string
  const rawTeaType = drink.base_tea_type;
  const teaTypeDisplay = rawTeaType && String(rawTeaType).trim() !== ''
    ? escapeHtml(rawTeaType)
    : 'Tea type unknown';

  // Handle price formatting
  const rawPrice = drink.price;
  const priceDisplay = (rawPrice !== null && rawPrice !== undefined)
    ? formatPrice(rawPrice)
    : null;
  const priceText = priceDisplay || 'Price not available';

  // Handle aggregates - may be missing entirely
  const aggregates = drink.aggregates || {};
  const ratingHtml = renderRating(aggregates);

  // Convert ID to string for href (handles numeric IDs)
  const idString = String(drink.id);

  return `
    <article class="drink-card" data-drink-id="${id}">
      <a href="/drinks/${idString}" class="drink-card-link">
        <h3 class="drink-name">${name}</h3>
        <p class="drink-tea-type">${teaTypeDisplay}</p>
        <p class="drink-price">${priceText}</p>
        <div class="drink-rating">
          ${ratingHtml}
        </div>
      </a>
    </article>
  `;
}

/**
 * Renders empty state
 * @returns {string} HTML string for empty state
 */
function renderEmptyState() {
  return `
    <div class="drink-list-empty">
      <p>No drinks available</p>
    </div>
  `;
}

/**
 * Validates input parameters
 * @param {*} drinks - Drinks array to validate
 * @param {*} container - Container element to validate
 * @throws {Error} If inputs are invalid
 */
function validateInputs(drinks, container) {
  if (!container || !(container instanceof Element)) {
    throw new Error('Container element is required');
  }

  if (!Array.isArray(drinks)) {
    throw new Error('Drinks must be an array');
  }
}

/**
 * Handles click events on drink cards
 * Dispatches custom navigation event
 * @param {Event} event - Click event
 */
function handleCardClick(event) {
  const link = event.currentTarget;
  const card = link.closest('.drink-card');
  if (!card) {
    return;
  }

  const drinkId = card.getAttribute('data-drink-id');
  const href = link.getAttribute('href');

  const navigateEvent = new CustomEvent('drink-list:navigate', {
    bubbles: true,
    detail: { drinkId, href }
  });

  card.dispatchEvent(navigateEvent);
}

/**
 * Attaches click handlers to drink card links
 * @param {HTMLElement} container - Container element
 */
function attachClickHandlers(container) {
  const links = container.querySelectorAll('.drink-card-link');
  links.forEach(link => {
    link.addEventListener('click', handleCardClick);
  });
}

/**
 * Renders a list of drinks into a container element
 * @param {Array} drinks - Array of drink objects
 * @param {HTMLElement} container - Container element to render into
 * @throws {Error} If inputs are invalid
 */
export function renderDrinkList(drinks, container) {
  validateInputs(drinks, container);

  // Clear container
  container.innerHTML = '';

  // Create wrapper
  const wrapper = document.createElement('div');
  wrapper.className = 'drink-list';

  if (drinks.length === 0) {
    wrapper.innerHTML = renderEmptyState();
  } else {
    const cardsHtml = drinks.map(drink => renderDrinkCard(drink)).join('');
    wrapper.innerHTML = cardsHtml;
  }

  container.appendChild(wrapper);

  // Attach click handlers
  attachClickHandlers(wrapper);
}

/**
 * Updates an existing drink list with new data
 * Re-renders the entire list
 * @param {Array} drinks - Array of drink objects
 * @param {HTMLElement} container - Container element to update
 * @throws {Error} If inputs are invalid
 */
export function updateDrinkList(drinks, container) {
  // Reuse renderDrinkList for simplicity
  renderDrinkList(drinks, container);
}

/**
 * Gets the drink ID from a child element within a drink card
 * Useful for event handling and navigation
 * @param {HTMLElement} element - Child element within a drink card
 * @returns {string|null} The drink ID or null if not found
 */
export function getDrinkIdFromElement(element) {
  if (!element || !(element instanceof Element)) {
    return null;
  }

  const card = element.closest('.drink-card');
  if (!card) {
    return null;
  }

  return card.getAttribute('data-drink-id');
}
