/**
 * Create Drink Form Component
 *
 * A form component for adding a new drink to a store with:
 * - Tea type dropdown (Black, Green, Oolong, White, Milk)
 * - Price input with validation
 * - Name and description fields
 * - Store selection
 * - API integration to POST /api/drinks
 */

// Valid tea type enum values
const VALID_TEA_TYPES = ['Black', 'Green', 'Oolong', 'White', 'Milk'];

/**
 * Initialize the create drink form component
 * @param {string} formSelector - CSS selector for the form element
 * @param {Object} options - Configuration options
 * @param {string} options.storeId - Pre-selected store ID (optional)
 * @param {string} options.redirectUrl - URL to redirect after success (optional)
 */
export function initCreateDrinkForm(formSelector = '[data-testid="create-drink-form"]', options = {}) {
  const form = document.querySelector(formSelector);

  if (!form) {
    console.warn('Create drink form not found:', formSelector);
    return null;
  }

  const state = {
    storeId: options.storeId || '',
    isSubmitting: false,
    errors: {},
  };

  // Initialize form fields
  initializeFormFields(form, state, options);

  // Bind form submission
  form.addEventListener('submit', handleFormSubmit.bind(null, form, state, options));

  // Bind field validation
  bindFieldValidation(form, state);

  return {
    form,
    state,
    destroy: () => destroy(form),
  };
}

/**
 * Initialize form field values and attributes
 */
function initializeFormFields(form, state, options) {
  // Set store ID if provided
  const storeSelect = form.querySelector('select[name="store_id"]');
  if (storeSelect && options.storeId) {
    storeSelect.value = options.storeId;
    state.storeId = options.storeId;
  }

  // Ensure tea type dropdown has correct options
  initializeTeaTypeDropdown(form);
}

/**
 * Initialize or validate the tea type dropdown options
 */
function initializeTeaTypeDropdown(form) {
  const teaTypeSelect = form.querySelector('select[name="base_tea_type"]');

  if (!teaTypeSelect) {
    return;
  }

  // Check if dropdown already has the correct options
  const existingOptions = Array.from(teaTypeSelect.options).map(opt => opt.value).filter(v => v);

  // If options are missing or incorrect, rebuild them
  const hasAllValidOptions = VALID_TEA_TYPES.every(type =>
    existingOptions.includes(type)
  );

  if (!hasAllValidOptions) {
    // Clear existing options except placeholder
    while (teaTypeSelect.options.length > 0) {
      teaTypeSelect.remove(0);
    }

    // Add placeholder option
    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = 'Select Tea Type';
    placeholder.disabled = true;
    placeholder.selected = true;
    teaTypeSelect.appendChild(placeholder);

    // Add valid tea type options
    VALID_TEA_TYPES.forEach(teaType => {
      const option = document.createElement('option');
      option.value = teaType;
      option.textContent = teaType;
      teaTypeSelect.appendChild(option);
    });
  }
}

/**
 * Bind validation to form fields
 */
function bindFieldValidation(form, state) {
  // Price field validation
  const priceInput = form.querySelector('input[name="price"]');
  if (priceInput) {
    priceInput.addEventListener('input', () => validatePrice(priceInput, state));
    priceInput.addEventListener('blur', () => validatePrice(priceInput, state));
  }

  // Name field validation
  const nameInput = form.querySelector('input[name="name"]');
  if (nameInput) {
    nameInput.addEventListener('blur', () => validateName(nameInput, state));
  }
}

/**
 * Validate price field
 * @param {HTMLInputElement} priceInput
 * @param {Object} state
 * @returns {boolean}
 */
function validatePrice(priceInput, state) {
  const priceValue = parseFloat(priceInput.value);
  const errorElement = document.querySelector('[data-testid="price-error"]') ||
                       priceInput.parentElement?.querySelector('.field-error');

  // Check for valid positive number
  const isValid = !isNaN(priceValue) && priceValue > 0;

  if (!isValid && priceInput.value !== '') {
    state.errors.price = 'Price must be a positive number';

    if (errorElement) {
      errorElement.textContent = 'Price must be a positive number';
      errorElement.classList.add('visible');
    }

    priceInput.classList.add('error');
    priceInput.setCustomValidity('Price must be positive');
  } else if (priceInput.value === '') {
    // Empty is OK (optional field)
    clearPriceError(priceInput, state);
  } else {
    // Valid positive price
    clearPriceError(priceInput, state);
  }

  return isValid || priceInput.value === '';
}

/**
 * Clear price validation error
 */
function clearPriceError(priceInput, state) {
  delete state.errors.price;

  const errorElement = document.querySelector('[data-testid="price-error"]') ||
                       priceInput.parentElement?.querySelector('.field-error');

  if (errorElement) {
    errorElement.textContent = '';
    errorElement.classList.remove('visible');
  }

  priceInput.classList.remove('error');
  priceInput.setCustomValidity('');
}

/**
 * Validate name field
 * @param {HTMLInputElement} nameInput
 * @param {Object} state
 * @returns {boolean}
 */
function validateName(nameInput, state) {
  const nameValue = nameInput.value.trim();
  const isValid = nameValue.length > 0;

  const errorElement = document.querySelector('[data-testid="name-error"]') ||
                       nameInput.parentElement?.querySelector('.field-error');

  if (!isValid) {
    state.errors.name = 'Drink name is required';

    if (errorElement) {
      errorElement.textContent = 'Drink name is required';
      errorElement.classList.add('visible');
    }

    nameInput.classList.add('error');
  } else {
    delete state.errors.name;

    if (errorElement) {
      errorElement.textContent = '';
      errorElement.classList.remove('visible');
    }

    nameInput.classList.remove('error');
  }

  return isValid;
}

/**
 * Validate all required fields
 * @param {HTMLFormElement} form
 * @param {Object} state
 * @returns {boolean}
 */
function validateForm(form, state) {
  const nameInput = form.querySelector('input[name="name"]');
  const storeSelect = form.querySelector('select[name="store_id"]');

  let isValid = true;

  // Validate name
  if (nameInput) {
    isValid = validateName(nameInput, state) && isValid;
  }

  // Validate store_id
  if (storeSelect) {
    const storeValid = storeSelect.value !== '';
    if (!storeValid) {
      state.errors.storeId = 'Store is required';
      const errorElement = document.querySelector('[data-testid="store-id-error"]') ||
                           storeSelect.parentElement?.querySelector('.field-error');
      if (errorElement) {
        errorElement.textContent = 'Store is required';
        errorElement.classList.add('visible');
      }
      isValid = false;
    }
  }

  // Validate price if provided
  const priceInput = form.querySelector('input[name="price"]');
  if (priceInput && priceInput.value !== '') {
    isValid = validatePrice(priceInput, state) && isValid;
  }

  return isValid;
}

/**
 * Handle form submission
 * @param {HTMLFormElement} form
 * @param {Object} state
 * @param {Object} options
 * @param {Event} event
 */
async function handleFormSubmit(form, state, options, event) {
  event.preventDefault();

  // Clear previous errors
  clearFormError(form);

  // Validate form
  if (!validateForm(form, state)) {
    return;
  }

  // Check for any remaining validation errors
  if (Object.keys(state.errors).length > 0) {
    return;
  }

  // Collect form data
  const formData = collectFormData(form);

  // Validate tea type if provided
  if (formData.base_tea_type && !VALID_TEA_TYPES.includes(formData.base_tea_type)) {
    showFormError(form, 'base_tea_type must be one of: ' + VALID_TEA_TYPES.join(', '));
    return;
  }

  // Submit to API
  await submitForm(form, state, options, formData);
}

/**
 * Collect form data into a structured object
 * @param {HTMLFormElement} form
 * @returns {Object}
 */
function collectFormData(form) {
  const data = {};

  // Store ID (required)
  const storeId = form.querySelector('select[name="store_id"]')?.value ||
                  form.querySelector('input[name="store_id"]')?.value;
  if (storeId) {
    data.store_id = storeId;
  }

  // Name (required)
  const name = form.querySelector('input[name="name"]')?.value?.trim();
  if (name) {
    data.name = name;
  }

  // Description (optional)
  const description = form.querySelector('textarea[name="description"]')?.value?.trim();
  if (description) {
    data.description = description;
  }

  // Base tea type (optional)
  const teaType = form.querySelector('select[name="base_tea_type"]')?.value;
  if (teaType) {
    data.base_tea_type = teaType;
  }

  // Price (optional)
  const priceValue = form.querySelector('input[name="price"]')?.value;
  if (priceValue && priceValue !== '') {
    const price = parseFloat(priceValue);
    if (!isNaN(price) && price > 0) {
      data.price = price;
    }
  }

  return data;
}

/**
 * Submit form data to API
 * @param {HTMLFormElement} form
 * @param {Object} state
 * @param {Object} options
 * @param {Object} formData
 */
async function submitForm(form, state, options, formData) {
  const submitButton = form.querySelector('button[type="submit"]');

  try {
    // Set submitting state
    state.isSubmitting = true;

    // Disable submit button
    if (submitButton) {
      submitButton.disabled = true;
      submitButton.setAttribute('disabled', 'disabled');
      const originalText = submitButton.textContent;
      submitButton.textContent = 'Creating...';
      submitButton.dataset.originalText = originalText;
    }

    // Make API request
    const response = await fetch('/api/drinks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData),
    });

    if (response.ok) {
      // Success - handle redirect
      const data = await response.json();
      handleSuccess(options, data);
    } else {
      // Error response
      const errorData = await response.json().catch(() => ({ error: 'An error occurred' }));
      handleApiError(form, response, errorData);
    }
  } catch (error) {
    // Network or other error
    showFormError(form, 'Network error. Please check your connection and try again.');
  } finally {
    // Reset state
    state.isSubmitting = false;

    // Re-enable submit button
    if (submitButton) {
      submitButton.disabled = false;
      submitButton.removeAttribute('disabled');
      if (submitButton.dataset.originalText) {
        submitButton.textContent = submitButton.dataset.originalText;
      }
    }
  }
}

/**
 * Handle successful form submission
 * @param {Object} options
 * @param {Object} data - Response data with drink id
 */
function handleSuccess(options, data) {
  const drinkId = data.id;
  const storeId = data.store_id;

  if (drinkId) {
    // Redirect to drink detail page
    window.location.href = `/drinks/${drinkId}`;
  } else if (storeId || options.storeId) {
    // Fallback: redirect to store page
    window.location.href = `/stores/${storeId || options.storeId}`;
  }
}

/**
 * Handle API error response
 * @param {HTMLFormElement} form
 * @param {Response} response
 * @param {Object} errorData
 */
function handleApiError(form, response, errorData) {
  let errorMessage;

  if (response.status === 400) {
    errorMessage = errorData.error || 'Invalid request. Please check your input.';
  } else if (response.status === 422) {
    errorMessage = errorData.error || 'Validation failed. Please check your input.';
  } else if (response.status === 404) {
    errorMessage = 'Store not found.';
  } else if (response.status >= 500) {
    errorMessage = 'An unexpected error occurred. Please try again.';
  } else {
    errorMessage = errorData.error || 'An error occurred. Please try again.';
  }

  showFormError(form, errorMessage);
}

/**
 * Show form-level error message
 * @param {HTMLFormElement} form
 * @param {string} message
 */
function showFormError(form, message) {
  const errorContainer = document.querySelector('[data-testid="form-error"]') ||
                         form.querySelector('.form-error');

  if (errorContainer) {
    errorContainer.textContent = message;
    errorContainer.classList.add('visible');
  }
}

/**
 * Clear form-level error message
 * @param {HTMLFormElement} form
 */
function clearFormError(form) {
  const errorContainer = document.querySelector('[data-testid="form-error"]') ||
                         form.querySelector('.form-error');

  if (errorContainer) {
    errorContainer.textContent = '';
    errorContainer.classList.remove('visible');
  }
}

/**
 * Clean up the form component
 * @param {HTMLFormElement} form
 */
function destroy(form) {
  // Remove event listeners would require storing references
  // For now, just clean up any dynamic elements
  const errorElements = form.querySelectorAll('.field-error.visible, .form-error.visible');
  errorElements.forEach(el => {
    el.textContent = '';
    el.classList.remove('visible');
  });
}

// Export constants for testing
export { VALID_TEA_TYPES };
