/**
 * Rating Display Component
 * Reusable component for displaying individual boba drink ratings
 * with boba-specific breakdown visualization
 */

/**
 * Escapes HTML special characters to prevent XSS
 * @param {string} text
 * @returns {string}
 */
function escapeHtml(text) {
  if (text == null) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Generates star rating HTML
 * @param {number} rating - Rating value 1-10
 * @returns {string}
 */
function renderStars(rating) {
  const fullStars = Math.floor(rating / 2);
  const hasHalfStar = rating % 2 === 1;
  const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

  let stars = '';

  // Full stars
  for (let i = 0; i < fullStars; i++) {
    stars += '<span class="star full">★</span>';
  }

  // Half star
  if (hasHalfStar) {
    stars += '<span class="star half">★</span>';
  }

  // Empty stars
  for (let i = 0; i < emptyStars; i++) {
    stars += '<span class="star empty">☆</span>';
  }

  return stars;
}

/**
 * Renders a metric bar
 * @param {string} label
 * @param {number} value - Value 1-10
 * @returns {string}
 */
function renderMetricBar(label, value) {
  const percentage = (value / 10) * 100;
  return `
    <div class="metric">
      <span class="metric-label">${escapeHtml(label)}</span>
      <div class="metric-bar-container">
        <div class="metric-bar" style="width: ${percentage}%"></div>
      </div>
      <span class="metric-value">${value}/10</span>
    </div>
  `;
}

/**
 * Creates a RatingCard component
 * @param {Object} rating - Rating data
 * @param {string} rating.id
 * @param {string} [rating.reviewer_name]
 * @param {number} rating.overall_rating - 1-10
 * @param {number} rating.sweetness - 1-10
 * @param {number} rating.boba_texture - 1-10
 * @param {number} rating.tea_strength - 1-10
 * @param {string} [rating.review_text]
 * @param {string} rating.created_at
 * @returns {HTMLElement}
 */
export function createRatingCard(rating) {
  if (!rating || typeof rating !== 'object') {
    throw new Error('Rating data is required');
  }

  if (rating.id == null) {
    throw new Error('Rating id is required');
  }

  const card = document.createElement('div');
  card.className = 'rating-card';
  card.setAttribute('data-rating-id', rating.id);

  // Overall rating section
  const overallRating = rating.overall_rating ?? 0;
  const reviewerName = rating.reviewer_name || 'Anonymous';

  // Format date
  let formattedDate = '';
  try {
    const date = new Date(rating.created_at);
    formattedDate = date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  } catch {
    formattedDate = rating.created_at || '';
  }

  // Build HTML structure
  let html = `
    <div class="rating-header">
      <div class="overall-rating">
        <span class="stars">${renderStars(overallRating)}</span>
        <span class="rating-number">${overallRating}/10</span>
      </div>
      <div class="reviewer-info">
        <span class="reviewer-name">By ${escapeHtml(reviewerName)}</span>
        <span class="review-date">${escapeHtml(formattedDate)}</span>
      </div>
    </div>
  `;

  // Boba-specific metrics breakdown (only if at least one metric exists)
  const hasMetrics = rating.sweetness != null || rating.boba_texture != null || rating.tea_strength != null;
  if (hasMetrics) {
    html += '<div class="boba-breakdown">';
    if (rating.sweetness != null) {
      html += renderMetricBar('Sweetness', rating.sweetness);
    }
    if (rating.boba_texture != null) {
      html += renderMetricBar('Boba Texture', rating.boba_texture);
    }
    if (rating.tea_strength != null) {
      html += renderMetricBar('Tea Strength', rating.tea_strength);
    }
    html += '</div>';
  }

  // Review text (expandable when provided)
  if (rating.review_text != null && rating.review_text !== '') {
    const reviewId = `review-${rating.id}`;
    html += `
      <div class="review-section">
        <button
          class="review-toggle"
          aria-expanded="false"
          aria-controls="${reviewId}"
          onclick="this.setAttribute('aria-expanded', this.getAttribute('aria-expanded') === 'false' ? 'true' : 'false'); this.nextElementSibling.classList.toggle('expanded')"
        >
          Show Review
        </button>
        <div id="${reviewId}" class="review-content">
          <div class="review-text">${escapeHtml(rating.review_text)}</div>
        </div>
      </div>
    `;
  }

  card.innerHTML = html;
  return card;
}

/**
 * Renders a list of rating cards
 * @param {HTMLElement} container
 * @param {Array<Object>} ratings
 */
export function renderRatingList(container, ratings) {
  if (!container || !(container instanceof HTMLElement)) {
    throw new Error('Valid container element is required');
  }

  container.innerHTML = '';

  if (!Array.isArray(ratings) || ratings.length === 0) {
    container.innerHTML = '<div class="ratings-empty">No ratings yet</div>';
    return;
  }

  ratings.forEach(rating => {
    const card = createRatingCard(rating);
    container.appendChild(card);
  });
}

/**
 * Mounts a single rating card to a container
 * @param {HTMLElement} container
 * @param {Object} rating
 */
export function mountRatingCard(container, rating) {
  if (!container || !(container instanceof HTMLElement)) {
    throw new Error('Valid container element is required');
  }

  const card = createRatingCard(rating);
  container.appendChild(card);
}

// Default styles (can be overridden by external CSS)
export const ratingCardStyles = `
  .rating-card {
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 16px;
    background: #fff;
    font-family: system-ui, -apple-system, sans-serif;
  }

  .rating-header {
    margin-bottom: 12px;
  }

  .overall-rating {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 4px;
  }

  .stars {
    color: #ffc107;
    font-size: 1.2em;
  }

  .star {
    margin-right: 2px;
  }

  .star.empty {
    color: #ddd;
  }

  .rating-number {
    font-weight: 600;
    color: #333;
  }

  .reviewer-info {
    display: flex;
    gap: 8px;
    font-size: 0.9em;
    color: #666;
  }

  .reviewer-name {
    font-weight: 500;
  }

  .boba-breakdown {
    margin: 12px 0;
    padding: 12px;
    background: #f8f9fa;
    border-radius: 6px;
  }

  .metric {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 8px;
  }

  .metric:last-child {
    margin-bottom: 0;
  }

  .metric-label {
    width: 90px;
    font-size: 0.85em;
    color: #555;
    flex-shrink: 0;
  }

  .metric-bar-container {
    flex: 1;
    height: 8px;
    background: #e0e0e0;
    border-radius: 4px;
    overflow: hidden;
  }

  .metric-bar {
    height: 100%;
    background: linear-gradient(90deg, #4caf50, #8bc34a);
    border-radius: 4px;
    transition: width 0.3s ease;
  }

  .metric-value {
    width: 40px;
    text-align: right;
    font-size: 0.85em;
    color: #666;
  }

  .review-section {
    margin-top: 12px;
  }

  .review-toggle {
    background: none;
    border: 1px solid #ddd;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.9em;
    color: #555;
  }

  .review-toggle:hover {
    background: #f5f5f5;
  }

  .review-toggle[aria-expanded="true"]::after {
    content: ' ▲';
  }

  .review-toggle[aria-expanded="false"]::after {
    content: ' ▼';
  }

  .review-content {
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.3s ease;
  }

  .review-content.expanded {
    max-height: 200px;
    overflow-y: auto;
  }

  .review-text {
    padding: 12px;
    margin-top: 8px;
    background: #f8f9fa;
    border-radius: 4px;
    white-space: pre-wrap;
    word-wrap: break-word;
    line-height: 1.5;
  }

  .ratings-empty {
    text-align: center;
    padding: 24px;
    color: #666;
    font-style: italic;
  }
`;
