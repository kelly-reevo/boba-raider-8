import { useState } from 'react';

/**
 * BobaRatingForm - Frontend form component for submitting boba-specific ratings
 *
 * Features:
 * - Sliders for sweetness, boba_texture, tea_strength (1-10 scale)
 * - Star selector for overall_rating (1-5 scale)
 * - Optional reviewer_name and review_text fields
 * - Inline validation with error messages
 * - API integration with POST /api/drinks/:id/ratings
 */

function BobaRatingForm({ drinkId, onClose, onSuccess }) {
  // Form state
  const [sweetness, setSweetness] = useState('');
  const [bobaTexture, setBobaTexture] = useState('');
  const [teaStrength, setTeaStrength] = useState('');
  const [overallRating, setOverallRating] = useState(0);
  const [reviewerName, setReviewerName] = useState('');
  const [reviewText, setReviewText] = useState('');

  // UI state
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState(null);
  const [showSuccess, setShowSuccess] = useState(false);

  // Validation
  const validateForm = () => {
    const newErrors = {};

    if (sweetness < 1 || sweetness > 10) {
      newErrors.sweetness = 'Sweetness must be between 1 and 10';
    }

    if (bobaTexture < 1 || bobaTexture > 10) {
      newErrors.bobaTexture = 'Boba texture must be between 1 and 10';
    }

    if (teaStrength < 1 || teaStrength > 10) {
      newErrors.teaStrength = 'Tea strength must be between 1 and 10';
    }

    if (overallRating < 1 || overallRating > 5) {
      newErrors.overallRating = 'Overall rating is required';
    }

    if (reviewText && reviewText.length > 2000) {
      newErrors.reviewText = 'Review must be 2000 characters or less';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitError(null);

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    // Build payload with fields in expected order
    const payload = {};

    if (reviewerName.trim()) {
      payload.reviewer_name = reviewerName.trim();
    }

    payload.overall_rating = overallRating;
    payload.sweetness = parseInt(sweetness, 10);
    payload.boba_texture = parseInt(bobaTexture, 10);
    payload.tea_strength = parseInt(teaStrength, 10);

    if (reviewText.trim()) {
      payload.review_text = reviewText.trim();
    }

    try {
      const response = await fetch(`/api/drinks/${drinkId}/ratings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error || 'Failed to submit rating');
      }

      const data = await response.json();

      // Show success message
      setShowSuccess(true);

      // Call success callback
      if (onSuccess) {
        onSuccess(data);
      }

      // Close form after brief delay to show success
      setTimeout(() => {
        if (onClose) {
          onClose();
        }
      }, 500);
    } catch (err) {
      setSubmitError(err.message || 'Failed to submit rating');
    } finally {
      setIsSubmitting(false);
    }
  };


  // Success state
  if (showSuccess) {
    return (
      <div className="boba-rating-form success-message" role="status">
        <p>Rating submitted successfully! Thank you!</p>
      </div>
    );
  }

  return (
    <form className="boba-rating-form" onSubmit={handleSubmit} noValidate>
      <h2>Rate This Drink</h2>

      {submitError && (
        <div className="error-banner" role="alert">
          {submitError}
        </div>
      )}

      {/* Sweetness Input */}
      <div className="form-field">
        <label htmlFor="sweetness">Sweetness</label>
        <input
          type="number"
          id="sweetness"
          name="sweetness"
          role="slider"
          aria-label="Sweetness"
          min="1"
          max="10"
          value={sweetness}
          onChange={(e) => setSweetness(e.target.value)}
        />
        {errors.sweetness && (
          <span className="error" role="alert">{errors.sweetness}</span>
        )}
      </div>

      {/* Boba Texture Input */}
      <div className="form-field">
        <label htmlFor="boba-texture">Boba Texture</label>
        <input
          type="number"
          id="boba-texture"
          name="bobaTexture"
          role="slider"
          aria-label="Boba Texture"
          min="1"
          max="10"
          value={bobaTexture}
          onChange={(e) => setBobaTexture(e.target.value)}
        />
        {errors.bobaTexture && (
          <span className="error" role="alert">{errors.bobaTexture}</span>
        )}
      </div>

      {/* Tea Strength Input */}
      <div className="form-field">
        <label htmlFor="tea-strength">Tea Strength</label>
        <input
          type="number"
          id="tea-strength"
          name="teaStrength"
          role="slider"
          aria-label="Tea Strength"
          min="1"
          max="10"
          value={teaStrength}
          onChange={(e) => setTeaStrength(e.target.value)}
        />
        {errors.teaStrength && (
          <span className="error" role="alert">{errors.teaStrength}</span>
        )}
      </div>

      {/* Overall Rating Star Selector */}
      <div className="form-field">
        <div className="star-selector">
          <label>Overall Rating</label>
          <div className="stars" role="group" aria-label="Overall rating">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                aria-label={`${star} star`}
                aria-pressed={overallRating === star ? "true" : "false"}
                className={`star ${overallRating >= star ? 'selected' : ''}`}
                onClick={() => setOverallRating(star)}
              >
                ★
              </button>
            ))}
          </div>
          {errors.overallRating && (
            <span className="error" role="alert">{errors.overallRating}</span>
          )}
        </div>
      </div>

      {/* Reviewer Name (Optional) */}
      <div className="form-field">
        <label htmlFor="reviewer-name">Reviewer Name (Optional)</label>
        <input
          type="text"
          id="reviewer-name"
          name="reviewerName"
          aria-label="Your name"
          value={reviewerName}
          onChange={(e) => setReviewerName(e.target.value)}
          placeholder="Your name"
        />
      </div>

      {/* Review Text (Optional) */}
      <div className="form-field">
        <label htmlFor="review-text">Review Text (Optional)</label>
        <textarea
          id="review-text"
          name="reviewText"
          role="textbox"
          aria-label="Review text"
          value={reviewText}
          onChange={(e) => setReviewText(e.target.value)}
          placeholder="Share your thoughts about this drink..."
          rows={4}
        />
        {errors.reviewText && (
          <span className="error" role="alert">{errors.reviewText}</span>
        )}
      </div>

      {/* Submit Button */}
      <div className="form-actions">
        <button
          type="submit"
          disabled={isSubmitting}
          className="submit-button"
        >
          {isSubmitting ? 'Submitting...' : 'Submit'}
        </button>
        {onClose && (
          <button
            type="button"
            onClick={onClose}
            className="cancel-button"
            disabled={isSubmitting}
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}

export default BobaRatingForm;
