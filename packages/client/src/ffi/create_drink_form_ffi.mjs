/**
 * FFI for Create Drink Form - JavaScript implementation of HTTP submission
 */

/**
 * Submit the create drink form to the API
 * @param {string} storeId
 * @param {string} name
 * @param {string} description
 * @param {string} baseTeaType
 * @param {string} price
 * @param {function} dispatch - Gleam dispatch function
 */
export function submitCreateDrink(storeId, name, description, baseTeaType, price, dispatch) {
  // Build the request body
  const body = {
    store_id: storeId,
    name: name,
  };

  // Add optional fields only if they have values
  if (description && description.trim() !== "") {
    body.description = description;
  }

  if (baseTeaType && baseTeaType !== "") {
    body.base_tea_type = baseTeaType;
  }

  if (price && price !== "") {
    const priceValue = parseFloat(price);
    if (!isNaN(priceValue) && priceValue > 0) {
      body.price = priceValue;
    }
  }

  // Make the API call
  fetch("/api/drinks", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  })
    .then(async (response) => {
      if (response.ok) {
        // Success - parse the response and dispatch success message
        const data = await response.json();
        if (data.id) {
          dispatch({ type: "CreateDrinkFormSubmitSuccess", drink_id: data.id });

          // Handle redirect on success
          window.location.href = `/drinks/${data.id}`;
        } else {
          dispatch({ type: "CreateDrinkFormSubmitError", error: "Invalid response from server" });
        }
      } else {
        // Error response
        const errorData = await response.json().catch(() => ({ error: "An error occurred" }));
        let errorMessage;

        if (response.status === 400) {
          errorMessage = errorData.error || "Invalid request. Please check your input.";
        } else if (response.status === 422) {
          errorMessage = errorData.error || "Validation failed. Please check your input.";
        } else if (response.status === 404) {
          errorMessage = "Store not found.";
        } else if (response.status >= 500) {
          errorMessage = "An unexpected error occurred. Please try again.";
        } else {
          errorMessage = errorData.error || "An error occurred. Please try again.";
        }

        dispatch({ type: "CreateDrinkFormSubmitError", error: errorMessage });
      }
    })
    .catch(() => {
      // Network error
      dispatch({
        type: "CreateDrinkFormSubmitError",
        error: "Network error. Please check your connection and try again.",
      });
    });
}
